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

func GetRelationKey(user1 uint32, user2 uint32) string {
	return strconv.FormatUint(uint64(user1), 16) + ":" +
		strconv.FormatUint(uint64(user2), 16)
}

func GetContactsKey(user uint32) string {
	return strconv.FormatUint(uint64(user), 16) + ContactsKey
}

func DBAddContact(user1 uint32, user2 uint32, flag uint32, name string) {
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

func DBRemoveContact(user1 uint32, user2 uint32) {
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

func dbEnableBits(user1 uint32, user2 uint32, bits uint32, c redis.Conn) error {
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

func dbDisableBits(user1 uint32, user2 uint32, bits uint32, c redis.Conn) error {
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

func DBSetName(user1 uint32, user2 uint32, name []byte) {
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

func getFlagDB(user1 uint32, user2 uint32, c redis.Conn) (uint32, error) {
	relateKey := GetRelationKey(user1, user2)
	result, err := redis.Int(c.Do("HMGET", relateKey, FlagField))
	if err != nil {
		return 0, err
	}
	return uint32(result), nil
}

func getNameDB(user1 uint32, user2 uint32, c redis.Conn) (string, error) {
	relateKey := GetRelationKey(user1, user2)
	result, err := redis.String(c.Do("HMGET", relateKey, NameField))
	if err != nil {
		return "", err
	}
	return result, nil
}

func GetContacts(userID uint32) (string, error) {
	var result string = ""
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		return "", err
	}
	defer c.Close()

	contactsKey := GetContactsKey(userID)
	numContacts, err := redis.Int(c.Do("SCARD", contactsKey))
	if err != nil {
		fmt.Println("redis get contacts size failed:", err)
	} else {
		result = result + "numOfContacts:" + strconv.Itoa(numContacts) + "\n"
		members, err := redis.Values(c.Do("SMEMBERS", contactsKey))
		if err != nil {
			fmt.Println("get contacts fail:", err)
		} else {
			for index, member := range members {
				contact, err := redis.Int(member, err)
				if err != nil {
					fmt.Println("redis get member fail:", err)
				}
				cont := uint32(contact)
				flag, err := getFlagDB(userID, cont, c)
				if err != nil {
					return "", err
				}
				name, err := getNameDB(userID, cont, c)
				if err != nil {
					return "", err
				}
				result = result +
					"idx:" + strconv.Itoa(index) + "," +
					"uid:" + strconv.FormatUint(uint64(cont), 16) + "," +
					"flg:" + strconv.FormatUint(uint64(flag), 16) + "," +
					"nam:" + name + "\n"
			}
		}
	}

	return result, nil
}