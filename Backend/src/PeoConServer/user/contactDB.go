package user

import (
	"fmt"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const ContactDB = "127.0.0.1:6379"
const FlagField = "flag"
const NameField = "name"
const ContactsKey = ":contacts"

func GetRelationKey(user1 uint64, user2 uint64) string {
	return strconv.FormatUint(user1, 16) + ":" +
		strconv.FormatUint(user2, 16)
}

func GetContactsKey(user uint64) string {
	return strconv.FormatUint(user, 16) + ContactsKey
}

func dbSearchContact(userID uint64, key string) (uint64, error) {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		return 0, err
	}
	defer c.Close()

	cellKey := getCellKey(key)
	exists, err := redis.Int64(c.Do("EXISTS", cellKey))
	if err != nil {
		return 0, err
	}
	if exists == 0 {
		return 0, fmt.Errorf("account not exists")
	}

	contact, err := redis.String(c.Do("GET", cellKey))
	if err != nil {
		return 0, err
	}
	_contact, err := strconv.Atoi(contact)
	if err != nil {
		return 0, err
	}
	contactID := uint64(_contact)

	flag, err := dbGetFlag(contactID, userID, c)
	if err != nil {
		return 0, err
	}
	if inBlacklist(flag) {
		return 0, fmt.Errorf("account not exists")
	}
	return contactID, nil
}

func dbAddContact(user1 uint64, user2 uint64, flag uint64, name string) error {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		return err
	}
	defer c.Close()

	_, err = c.Do("MULTI")
	if err != nil {
		return err
	}

	relateKey := GetRelationKey(user1, user2)
	_, err = c.Do("HMSET", relateKey,
		FlagField, flag,
		NameField, name)
	if err != nil {
		return err
	}

	contactsKey := GetContactsKey(user1)
	_, err = c.Do("SADD", contactsKey, user2)
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
	c, err := redis.Dial("tcp", ContactDB)
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

func dbEnableBits(user1 uint64, user2 uint64, bits uint64, c redis.Conn) error {
	flag, err := dbGetFlag(user1, user2, c)
	if err != nil {
		return err
	}

	flag = (flag | bits)

	relateKey := GetRelationKey(user1, user2)
	_, err = c.Do("HMSET", relateKey, FlagField, flag)
	if err != nil {
		return err
	}
	return nil
}

func dbDisableBits(user1 uint64, user2 uint64, bits uint64, c redis.Conn) error {
	flag, err := dbGetFlag(user1, user2, c)
	if err != nil {
		return err
	}

	flag = (flag & (^bits))

	relateKey := GetRelationKey(user1, user2)
	_, err = c.Do("HMSET", relateKey, FlagField, flag)
	if err != nil {
		return err
	}

	return nil
}

func dbSetName(user1 uint64, user2 uint64, name []byte) {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	relateKey := GetRelationKey(user1, user2)
	_, err = c.Do("HMSET", relateKey, NameField, name)
	if err != nil {
		fmt.Println("update name fail:", err)
	}
}

func dbGetFlag(user1 uint64, user2 uint64, c redis.Conn) (uint64, error) {
	relationKey := GetRelationKey(user1, user2)
	exists, err := redis.Int64(c.Do("EXISTS", relationKey))
	if err != nil {
		return 0, err
	}
	if exists == 0 {
		return 0, nil // 0 means no relation
	}

	values, err := redis.Values(c.Do("HMGET", relationKey, FlagField))
	relationStr, err := redis.String(values[0], err)
	if err != nil {
		return 0, err
	}
	relation, err := strconv.Atoi(relationStr)
	if err != nil {
		return 0, err
	}

	return uint64(relation), nil
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
			contactStr, err := redis.String(member, err)
			if err != nil {
				return nil, err
			}
			contact, err := strconv.Atoi(contactStr)
			if err != nil {
				return nil, err
			}
			contactID := uint64(contact)
			relateKey := GetRelationKey(userID, contactID)
			values, err := redis.Values(c.Do("HMGET", relateKey, FlagField, NameField))
			flagStr, err := redis.String(values[0], err)
			name, err := redis.String(values[1], err)
			if err != nil {
				return nil, err
			}
			flag, err := strconv.Atoi(flagStr)
			if err != nil {
				return nil, err
			}
			var newContact ContactInfo
			newContact.User = contactID
			newContact.Flag = uint64(flag)
			newContact.Name = name
			contacts = append(contacts, newContact)
		}
	}

	return contacts, nil
}
