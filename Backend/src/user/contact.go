package user

import (
	"encoding/json"
	"fmt"
	"share"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const FlagField = "flag"
const NameField = "name"
const MessField = "mess"

const NAME_SIZE uint32 = 20

type ContactInfo struct {
	User uint64 `json:"user"`
	Flag uint64 `json:"flag"`
	Name string `json:"name"`
}

func GetContactsKey(user uint64) string {
	return "contacts:" + strconv.FormatUint(user, 10)
}

// todo, build search tree
func dbSearchContact(userID uint64, key string, c redis.Conn) (uint64, error) {
	cellKey := getCellKey(0, key)
	exists, err := redis.Int64(c.Do("EXISTS", cellKey))
	if err != nil {
		return 0, err
	}
	if exists == 0 {
		return 0, fmt.Errorf("account not exists")
	}

	account, err := redis.String(c.Do("GET", cellKey))
	if err != nil {
		return 0, err
	}
	contactID, err := getAccountID(account)
	if err != nil {
		return 0, err
	}

	flag, _, err := GetCashFlag(contactID, userID, c)
	if err != nil {
		return 0, err
	}
	if inBlacklist(flag) {
		return 0, fmt.Errorf("account not exists")
	}
	return contactID, nil
}

type RequestInfo struct {
	From uint64 `json:"from"`
	Name string `json:"name"`
	Msg  string `json:"msg"`
}

func dbAddContact(user1 uint64, user2 uint64, name string, c redis.Conn) error {
	ClearCashRelation(user1, user2)

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

	user1RelateKey := GetRelationKey(user1, user2)
	_, err = c.Do("HMSET", user1RelateKey,
		FlagField, UDF_BIT,
		NameField, name)
	if err != nil {
		return err
	}
	user2RelateKey := GetRelationKey(user2, user1)
	_, err = c.Do("HMSET", user2RelateKey,
		FlagField, UDF_BIT,
		NameField, request.Name)
	if err != nil {
		return err
	}

	user1ContactsKey := GetContactsKey(user1)
	_, err = c.Do("SADD", user1ContactsKey, user2)
	if err != nil {
		return err
	}
	user2ContactsKey := GetContactsKey(user2)
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
	return nil
}

func dbRemoveContact(user1 uint64, user2 uint64) error {
	ClearCashRelation(user1, user2)
	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		return err
	}
	defer c.Close()

	_, err = c.Do("MULTI")
	if err != nil {
		return err
	} else {
		relateKey := GetRelationKey(user1, user2)
		_, err = c.Do("DEL", relateKey)
		if err != nil {
			return err
		}

		contactsKey := GetContactsKey(user1)
		_, err = c.Do("SREM", contactsKey, user2)
		if err != nil {
			return err
		}

		_, err = c.Do("EXEC")
		if err != nil {
			return err
		}
	}

	return nil
}

func dbGetContacts(userID uint64, c redis.Conn) ([]ContactInfo, error) {
	var contacts []ContactInfo
	contactsKey := GetContactsKey(userID)
	numContacts, err := redis.Int(c.Do("SCARD", contactsKey))
	if err != nil {
		return nil, err
	}

	if numContacts > 0 {
		members, err := redis.Values(c.Do("SMEMBERS", contactsKey))
		if err != nil {
			return nil, err
		}

		for _, member := range members {
			contactID, err := share.GetUint64(member, err)
			if err != nil {
				return nil, err
			}
			relateKey := GetRelationKey(userID, contactID)
			values, err := redis.Values(c.Do("HMGET", relateKey, FlagField, NameField))
			flag, err := share.GetUint64(values[0], err)
			name, err := redis.String(values[1], err)
			if err != nil {
				return nil, err
			}

			var newContact ContactInfo
			newContact.User = contactID
			newContact.Flag = flag
			newContact.Name = name
			contacts = append(contacts, newContact)
		}
	}

	return contacts, nil
}
