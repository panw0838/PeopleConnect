package user

import (
	"encoding/json"
	"net/http"
	"share"

	"github.com/garyburd/redigo/redis"
)

type GetUserDetailInput struct {
	UID uint64 `json:"uid"`
	CID uint64 `json:"cid"`
}

type GetUserDetailReturn struct {
	Like bool `json:"like"`
}

func GetUserDetailHandler(w http.ResponseWriter, r *http.Request) {
	var input GetUserDetailInput
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

	var response GetUserDetailReturn

	likeUKey := share.GetLikeUserKey(input.CID)
	like, err := redis.Int(c.Do("SISMEMBER", likeUKey, input.UID))
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	response.Like = (like == 1)

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

type Users struct {
	Users []User `json:"users"`
}

func GetBothLikeStrangersHandler(w http.ResponseWriter, r *http.Request) {
	var input AccountInfo
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

	likeUKey := share.GetLikeUserKey(input.UserID)
	uLikeKey := share.GetUserLikeKey(input.UserID)

	users, err := redis.Int64s(c.Do("SINTER", likeUKey, uLikeKey))
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var response Users

	for _, user := range users {
		uID := uint64(user)

		isStranger, err := IsStranger(input.UserID, uID, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		if isStranger {
			var newUser User
			newUser.UID = uID
			newUser.Name, err = DbGetUserName(uID, c)
			if err != nil {
				share.WriteErrorCode(w, err)
				return
			}
			response.Users = append(response.Users, newUser)
		}
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

func GetLikeMeUsersHandler(w http.ResponseWriter, r *http.Request) {
	var input AccountInfo
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

	likeUKey := share.GetLikeUserKey(input.UserID)

	users, err := redis.Int64s(c.Do("SMEMBERS", likeUKey))
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var response Users

	for _, user := range users {
		uID := uint64(user)

		isBlacklist, err := IsBlacklist(input.UserID, uID, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		if !isBlacklist {
			var newUser User
			newUser.UID = uID
			newUser.Name, err = DbGetUserName(uID, c)
			if err != nil {
				share.WriteErrorCode(w, err)
				return
			}
			response.Users = append(response.Users, newUser)
		}
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)

}
