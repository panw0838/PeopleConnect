package message

import (
	"net/http"
	"share"
	"user"

	"github.com/garyburd/redigo/redis"
)

type AddContactInput struct {
	User    uint64 `json:"user"`
	Contact uint64 `json:"contact"`
	Name    string `json:"name"`
}

func AddContactHandler(w http.ResponseWriter, r *http.Request) {
	var input AddContactInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	if input.User == input.Contact {
		share.WriteErrorCode(w, err)
		return
	}

	nameLen := len(input.Name)
	if nameLen == 0 || nameLen > int(user.NAME_SIZE) {
		share.WriteErrorCode(w, err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	err = dbAddContact(input.User, input.Contact, input.Name, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
}

type RemContactInput struct {
	User    uint64 `json:"user"`
	Contact uint64 `json:"contact"`
}

func RemContactHandler(w http.ResponseWriter, r *http.Request) {
	var input RemContactInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	err = dbRemoveContact(input.User, input.Contact)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
}

type LikeUserInput struct {
	UID  uint64 `json:"uid"`
	CID  uint64 `json:"cid"`
	Like bool   `json:"like"`
}

func LikeUserHandler(w http.ResponseWriter, r *http.Request) {
	var input LikeUserInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	uLikeKey := share.GetUserLikeKey(input.UID)
	likeUkey := share.GetLikeUserKey(input.CID)
	if input.Like {
		_, err := c.Do("MULTI")
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		_, err = c.Do("SADD", likeUkey, input.UID)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		_, err = c.Do("SADD", uLikeKey, input.CID)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		_, err = c.Do("EXEC")
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		var msg Message
		msg.From = input.UID
		msg.Type = NTF_LIK
		_, err = DbAddMessege(input.CID, msg, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
	} else {
		_, err := c.Do("MULTI")
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		_, err = c.Do("SREM", likeUkey, input.UID)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		_, err = c.Do("SREM", uLikeKey, input.CID)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		_, err = c.Do("EXEC")
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
	}

	share.WriteError(w, 0)
}
