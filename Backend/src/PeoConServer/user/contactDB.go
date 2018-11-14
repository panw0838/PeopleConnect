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

func DBAddContact(user1 uint64, user2 uint64, flag uint64, name string) {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	_, err = c.Do("MULTI")
	if err != nil {
		fmt.Println("add contact fail:", err)
	} else {
		relateKey := GetRelationKey(user1, user2)
		_, err = c.Do("HMSET", relateKey,
			FlagField, flag,
			NameField, name)
		if err != nil {
			fmt.Println("set relation fields fail:", err)
		}

		contactsKey := string(user1) + ContactsKey
		_, err = c.Do("SADD", contactsKey, user2)
		if err != nil {
			fmt.Println("add contact fail:", err)
		}

		_, err = c.Do("EXEC")
		if err != nil {
			fmt.Println("add contact fail:", err)
		}
	}
}

func DBRemoveContact(user1 uint64, user2 uint64) {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	_, err = c.Do("MULTI")
	if err != nil {
		fmt.Println("add contact fail:", err)
	} else {
		relateKey := GetRelationKey(user1, user2)
		_, err = c.Do("DEL", relateKey)
		if err != nil {
			fmt.Println("del relation fields fail:", err)
		}

		contactsKey := string(user1) + ContactsKey
		_, err = c.Do("SREM", contactsKey, user2)
		if err != nil {
			fmt.Println("remove contact fail:", err)
		}

		_, err = c.Do("EXEC")
		if err != nil {
			fmt.Println("remove contact fail:", err)
		}
	}
}

func dbEnableBits(user1 uint64, user2 uint64, bits uint64, c redis.Conn) error {
	flag, err := getFlagDB(user1, user2, c)
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
	flag, err := getFlagDB(user1, user2, c)
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

func DBSetName(user1 uint64, user2 uint64, name []byte) {
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

func getFlagDB(user1 uint64, user2 uint64, c redis.Conn) (uint64, error) {
	relateKey := GetRelationKey(user1, user2)
	result, err := redis.Uint64(c.Do("HMGET", relateKey, FlagField))
	if err != nil {
		return 0, err
	}
	return result, nil
}

func getNameDB(user1 uint64, user2 uint64, c redis.Conn) (string, error) {
	relateKey := GetRelationKey(user1, user2)
	result, err := redis.String(c.Do("HMGET", relateKey, NameField))
	if err != nil {
		return "", err
	}
	return result, nil
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
