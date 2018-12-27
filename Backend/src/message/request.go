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

func dbAddContact(user1 uint64, user2 uint64, name string, c redis.Conn) error {
	user.ClearCashRelation(user1, user2)

	requestsKey := share.GetRequestsKey(user2)

	values, err := redis.Values(c.Do("ZRANGE", requestsKey, user1, user1))
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

	user1RelateKey := user.GetRelationKey(user1, user2)
	_, err = c.Do("HMSET", user1RelateKey,
		user.FlagField, user.UDF_BIT,
		user.NameField, name)
	if err != nil {
		return err
	}
	user2RelateKey := user.GetRelationKey(user2, user1)
	_, err = c.Do("HMSET", user2RelateKey,
		user.FlagField, user.UDF_BIT,
		user.NameField, request.Name)
	if err != nil {
		return err
	}

	user1ContactsKey := user.GetContactsKey(user1)
	_, err = c.Do("SADD", user1ContactsKey, user2)
	if err != nil {
		return err
	}
	user2ContactsKey := user.GetContactsKey(user2)
	_, err = c.Do("SADD", user2ContactsKey, user1)
	if err != nil {
		return err
	}

	_, err = c.Do("ZREMRANGEBYSCORE", requestsKey, user1, user1)
	if err != nil {
		return err
	}

	_, err = c.Do("EXEC")
	if err != nil {
		return err
	}

	user.ClearCashRelation(user1, user2)
	// add to message notification
	var msg Message
	msg.From = user1
	msg.Type = NTF_ADD
	err = dbAddMessege(user2, msg, c)
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
