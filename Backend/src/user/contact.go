package user

import (
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

func GetRelationKey(user1 uint64, user2 uint64) string {
	return "relate:" +
		strconv.FormatUint(user1, 10) + ":" +
		strconv.FormatUint(user2, 10)
}

func GetContactsKey(user uint64) string {
	return "contacts:" + strconv.FormatUint(user, 10)
}

func AddContactPreCheck(from uint64, to uint64, flag uint64, name string) error {
	if from == to {
		return fmt.Errorf("can't request self")
	}

	nameLen := len(name)
	if nameLen == 0 || nameLen > int(NAME_SIZE) {
		return fmt.Errorf("invalid contact name")
	}

	if flag == 0 || flag&BLK_BIT != 0 {
		return fmt.Errorf("invalid group")
	}

	return nil
}

func dbSearchContact(userID uint64, key string, c redis.Conn) (uint64, error) {
	cellKey := getCellKey(key)
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

	flag, err := DbGetFlag(contactID, userID, c)
	if err != nil {
		return 0, err
	}
	if inBlacklist(flag) {
		return 0, fmt.Errorf("account not exists")
	}
	return contactID, nil
}

func dbAddContact(user1 uint64, user2 uint64, flag uint64, name string, c redis.Conn) error {
	requestKey := share.GetRequestKey(user2, user1)
	values, err := redis.Values(c.Do("HMGET", requestKey, FlagField, NameField))
	if err != nil {
		return err
	}
	otherFlag, err := share.GetUint64(values[0], err)
	otherName, err := redis.String(values[1], err)
	if err != nil {
		return err
	}

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
	otherRelateKey := GetRelationKey(user2, user1)
	_, err = c.Do("HMSET", otherRelateKey,
		FlagField, otherFlag,
		NameField, otherName)
	if err != nil {
		return err
	}

	contactsKey := GetContactsKey(user1)
	_, err = c.Do("SADD", contactsKey, user2)
	if err != nil {
		return err
	}
	otherContactsKey := GetContactsKey(user2)
	_, err = c.Do("SADD", otherContactsKey, user1)
	if err != nil {
		return err
	}

	_, err = c.Do("DEL", requestKey)
	if err != nil {
		return err
	}

	requestsKey := share.GetRequestsKey(user2)
	_, err = c.Do("SREM", requestsKey, user1)
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

func dbEnableBits(user1 uint64, user2 uint64, bits uint64, c redis.Conn) error {
	flag, err := DbGetFlag(user1, user2, c)
	if err != nil {
		return err
	}
	// if flag is 0, user has no relation with contact
	if flag == 0 {
		return fmt.Errorf("invalid contact")
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
	flag, err := DbGetFlag(user1, user2, c)
	if err != nil {
		return err
	}
	// if flag is 0, user has no relation with contact
	if flag == 0 {
		return fmt.Errorf("invalid contact")
	}

	flag = (flag & (^bits))

	relateKey := GetRelationKey(user1, user2)
	_, err = c.Do("HMSET", relateKey, FlagField, flag)
	if err != nil {
		return err
	}

	return nil
}

func dbSetName(user1 uint64, user2 uint64, name []byte) error {
	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		return err
	}
	defer c.Close()

	relateKey := GetRelationKey(user1, user2)
	_, err = c.Do("HMSET", relateKey, NameField, name)
	if err != nil {
		return err
	}

	return nil
}

func DbGetFlag(user1 uint64, user2 uint64, c redis.Conn) (uint64, error) {
	relationKey := GetRelationKey(user1, user2)
	exists, err := redis.Int64(c.Do("EXISTS", relationKey))
	if err != nil {
		return 0, err
	}
	if exists == 0 {
		return 0, nil // 0 means no relation
	}

	values, err := redis.Values(c.Do("HMGET", relationKey, FlagField))
	relation, err := share.GetUint64(values[0], err)
	if err != nil {
		return 0, err
	}

	return relation, nil
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
