package user

import (
	"fmt"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const TagKey = ":tag"

func GetTagKey(userID uint32) string {
	return strconv.FormatUint(uint64(userID), 16) + ":" + TagKey
}

func getTagInfo(tagString string) (byte, string) {
	var data []byte = []byte(tagString)
	var fatherID = data[0]
	var tagName string = string(data[1:])
	return fatherID, tagName
}

func getTagData(fatherID byte, name string) string {
	var fatherData []byte = []byte{fatherID}
	var nameData []byte = []byte(name)
	return string(append(fatherData, nameData...))
}

func dbAddTagPrecheck(userID uint32, fatherID uint32, c redis.Conn) error {
	tagKey := GetTagKey(userID)
	numTags, err := redis.Int(c.Do("LLEN", tagKey))
	if err != nil {
		return err
	}

	// check father tag
	if int(fatherID) > numTags {
		return fmt.Errorf("Invalid father tag")
	}

	if fatherID >= USER_TAG_START {
		fatherIndex := fatherID - USER_TAG_START
		fatherTag, err := redis.String(c.Do("LINDEX", tagKey, fatherIndex))
		if err != nil {
			return err
		}

		// father not exists
		if len(fatherTag) == 0 {
			return fmt.Errorf("Invalid father tag")
		}

		// father has gradpa
		gradpa, _ := getTagInfo(fatherTag)
		if gradpa != 0 {
			return fmt.Errorf("Invalid father tag")
		}
	}

	return nil
}

func dbAddTag(userID uint32, fatherID byte, name string, c redis.Conn) (int, error) {
	tagKey := GetTagKey(userID)
	data := getTagData(fatherID, name)

	// find empty tag
	tags, err := redis.Strings(c.Do("LRANGE", tagKey, 0, MAX_USER_TAGS))
	if err != nil {
		return -1, err
	} else {
		for index, tag := range tags {
			if len(tag) == 0 {
				_, err = c.Do("LSET", tagKey, index, data)
				if err != nil {
					return -1, err
				} else {
					return index, nil
				}
			}
		}
	}

	numTags, err := redis.Int(c.Do("LLEN", tagKey))
	if err != nil {
		return -1, err
	}

	if uint32(numTags) >= MAX_USER_TAGS {
		return -1, fmt.Errorf("Reach max tags")
	} else {
		// add brand new tag
		_, err = c.Do("RPUSH", tagKey, data)
		if err != nil {
			return -1, err
		} else {
			return numTags, nil
		}
	}
}

func dbUserTagExists(userID uint32, tagID uint32, c redis.Conn) (bool, error) {
	tagKey := GetTagKey(userID)
	tagIndex := tagID - USER_TAG_START
	tag, err := redis.String(c.Do("LINDEX", tagKey, tagIndex))
	if err != nil {
		return false, err
	}
	if len(tag) > 0 {
		return true, nil
	}
	return false, nil
}

func dbCheckSubTag(userID uint32, tagID uint32, c redis.Conn) (bool, error) {
	tagKey := GetTagKey(userID)

	// find empty tag
	tags, err := redis.Strings(c.Do("LRANGE", tagKey, 0, MAX_USER_TAGS))
	if err != nil {
		return false, err
	} else {
		for _, tag := range tags {
			if len(tag) != 0 {
				fatherID, _ := getTagInfo(tag)
				if uint32(fatherID) == tagID {
					return true, nil
				}
			}
		}
	}

	return false, nil
}

func dbCheckMember(userID uint32, tagID uint32, c redis.Conn) (bool, error) {
	contactsKey := GetContactsKey(userID)
	bit := uint32(^(1 << tagID))
	members, err := redis.Values(c.Do("SMEMBERS", contactsKey))
	if err != nil {
		return false, err
	} else {
		for _, member := range members {
			contact, err := redis.Int(member, err)
			if err != nil {
				return false, err
			}
			cont := uint32(contact)
			flag, err := getFlagDB(userID, cont, c)
			if err != nil {
				return false, err
			}
			if (flag | bit) != uint32(0) {
				return true, nil
			}
		}
	}
	return false, nil
}

func dbRemTag(userID uint32, tagID uint32, c redis.Conn) error {
	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		return err
	}
	defer c.Close()

	tagKey := GetTagKey(userID)
	numTags, err := redis.Int(c.Do("LLEN", tagKey))
	if err != nil {
		return err
	}

	if int(tagID) < numTags {
		_, err = c.Do("LSET", tagKey, tagID, "")
		if err != nil {
			return err
		}
	} else {
		return fmt.Errorf("Remove tag out of range")
	}

	return nil
}