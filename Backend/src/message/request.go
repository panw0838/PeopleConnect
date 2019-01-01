package message

import (
	"encoding/json"
	"fmt"
	"share"
	"user"

	"github.com/garyburd/redigo/redis"
)

type RequestInfo struct {
	From uint64 `json:"from"`
	Name string `json:"name"`
	Msg  string `json:"msg"`
}

func dbAddContact(uID uint64, cID uint64, name string, c redis.Conn) error {
	requestsKey := share.GetRequestsKey(uID)
	values, err := redis.Values(c.Do("ZRANGEBYSCORE", requestsKey, cID, cID))
	if len(values) != 1 {
		return fmt.Errorf("no request info")
	}
	data, err := redis.Bytes(values[0], err)
	if err != nil {
		return err
	}

	var request RequestInfo
	err = json.Unmarshal(data, &request)
	if err != nil {
		return err
	}

	_, err = c.Do("MULTI")
	if err != nil {
		return err
	}

	user1RelateKey := user.GetRelationKey(uID, cID)
	_, err = c.Do("HMSET", user1RelateKey,
		user.FlagField, user.UDF_BIT,
		user.NameField, name)
	if err != nil {
		return err
	}
	user2RelateKey := user.GetRelationKey(cID, uID)
	_, err = c.Do("HMSET", user2RelateKey,
		user.FlagField, user.UDF_BIT,
		user.NameField, request.Name)
	if err != nil {
		return err
	}

	user1ContactsKey := user.GetContactsKey(uID)
	_, err = c.Do("SADD", user1ContactsKey, cID)
	if err != nil {
		return err
	}
	user2ContactsKey := user.GetContactsKey(cID)
	_, err = c.Do("SADD", user2ContactsKey, uID)
	if err != nil {
		return err
	}

	_, err = c.Do("ZREMRANGEBYSCORE", requestsKey, cID, cID)
	if err != nil {
		return err
	}

	_, err = c.Do("EXEC")
	if err != nil {
		return err
	}

	user.ClearCashRelation(uID, cID)
	// add to message notification
	var msg Message
	msg.From = uID
	msg.Type = NTF_ADD
	err = DbAddMessege(cID, msg, c)
	if err != nil {
		return err
	}

	return nil
}

func dbRemoveContact(user1 uint64, user2 uint64) error {
	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		return err
	}
	defer c.Close()

	_, err = c.Do("MULTI")
	if err != nil {
		return err
	} else {
		relateKey := user.GetRelationKey(user1, user2)
		_, err = c.Do("DEL", relateKey)
		if err != nil {
			return err
		}

		contactsKey := user.GetContactsKey(user1)
		_, err = c.Do("SREM", contactsKey, user2)
		if err != nil {
			return err
		}

		_, err = c.Do("EXEC")
		if err != nil {
			return err
		}
	}

	user.ClearCashRelation(user1, user2)
	return nil
}
