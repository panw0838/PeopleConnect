package user

import (
	"fmt"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const ContactDB = "127.0.0.1:6379"

func GetFlagKey(user1 uint32, user2 uint32) string {
	return string(user1) + ":" + string(user2) + ":flag"
}

func GetNameKey(user1 uint32, user2 uint32) string {
	return string(user1) + ":" + string(user2) + ":name"
}

func GetContactsKey(user1 uint32) string {
	return string(user1) + ":contacts"
}

func AddContactIntoTable(user1 uint32, user2 uint32, flag uint32, name []byte) {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	flagKey := GetFlagKey(user1, user2)
	_, err = c.Do("SET ", flagKey, flag)
	if err != nil {
		fmt.Println("redis set failed:", err)
	}

	nameKey := GetNameKey(user1, user2)
	_, err = c.Do("SET ", nameKey, name)
	if err != nil {
		fmt.Println("redis set failed:", err)
	}

	contactsKey := string(user1) + ":contacts"
	_, err = c.Do("SADD ", contactsKey, user2)
	if err != nil {
		fmt.Println("redis set failed:", err)
	}
}

func RemoveContactFromTable(user1 uint32, user2 uint32) {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	flagKey := GetFlagKey(user1, user2)
	_, err = c.Do("DEL ", flagKey)
	if err != nil {
		fmt.Println("redis set failed:", err)
	}

	nameKey := GetNameKey(user1, user2)
	_, err = c.Do("DEL ", nameKey)
	if err != nil {
		fmt.Println("redis set failed:", err)
	}

	contactsKey := string(user1) + ":contacts"
	_, err = c.Do("SREM ", contactsKey, user2)
	if err != nil {
		fmt.Println("redis set failed:", err)
	}
}

func UpdateContactInTable(user1 uint32, user2 uint32, flag uint32, name []byte) {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	flagKey := GetFlagKey(user1, user2)
	_, err = c.Do("SET ", flagKey, flag)
	if err != nil {
		fmt.Println("redis set failed:", err)
	}

	nameKey := GetNameKey(user1, user2)
	_, err = c.Do("SET ", nameKey, name)
	if err != nil {
		fmt.Println("redis set failed:", err)
	}
}

func getStringValue(key string, c redis.Conn) string {
	result, err := redis.String(c.Do("GET", key))
	if err != nil {
		fmt.Println("redis set failed:", err)
	}
	return result
}

func getUint32Value(key string, c redis.Conn) uint32 {
	var result int = 0
	value, err := redis.String(c.Do("GET", key))
	if err != nil {
		fmt.Println("redis set failed:", err)
	} else {
		result, err = strconv.Atoi(value)
		if err != nil {
			fmt.Println("convert key %s %s to uint fail", key, value)
		}
	}
	return uint32(result)
}

func LoadContact(idString string) *ContactInfo {

}

func GetContacts(userID uint32) {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	contactsKey := string(userID) + ":contacts"
	values, err := redis.Values(c.Do("SMEMBERS ", contactsKey))
	if err != nil {
		fmt.Println("redis set failed:", err)
	} else {
		for _, v := range values {
			user2 := string(v.([]byte))
			flagKey := string(userID) + ":" + user2 + ":flag"
			nameKey := string(userID) + ":" + user2 + ":name"
			contactInfo.flag := getUint32Value(flagKey, c)
			contactInfo.name := getStringValue(nameKey, c)
		}
	}
}
