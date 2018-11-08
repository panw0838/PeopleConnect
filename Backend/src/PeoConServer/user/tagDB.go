package user

import (
	"fmt"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const TagKey = ":tag"

func GetTagKey(userID uint64) string {
	return strconv.FormatUint(uint64(userID), 16) + ":" + TagKey
}

func getTagInfo(tagString string) (uint64, string) {
	var data []byte = []byte(tagString)
	var fatherID = uint64(data[0])
	var tagName string = string(data[1:])
	return fatherID, tagName
}

func getTagData(fatherID uint64, name string) string {
	var fatherData []byte = []byte{byte(fatherID)}
	var nameData []byte = []byte(name)
	return string(append(fatherData, nameData...))
}

func getTagBits(userID uint64, tagID uint64, c redis.Conn) (uint64, error) {
	var bits uint64 = (1 << tagID)

	if isSystemTag(tagID) {
		return bits, nil
	} else {
		tagKey := GetTagKey(userID)
		tagIdx := getUserTagIdx(tagID)
		tagData, err := redis.String(c.Do("LINDEX", tagKey, tagIdx))
		if err != nil {
			return ZERO_64, err
		}
		fatherID, _ := getTagInfo(tagData)
		if fatherID != ZERO_64 {
			bits |= (1 << fatherID)
		}
		return bits, nil
	}
}

func dbAddTagPrecheck(userID uint64, fatherID uint64, c redis.Conn) error {
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

func dbAddTag(userID uint64, fatherID uint64, name string, c redis.Conn) (uint64, error) {
	tagKey := GetTagKey(userID)
	data := getTagData(fatherID, name)

	// find empty tag
	tags, err := redis.Strings(c.Do("LRANGE", tagKey, 0, MAX_USER_TAGS))
	if err != nil {
		return 0, err
	} else {
		for index, tag := range tags {
			if len(tag) == 0 {
				_, err = c.Do("LSET", tagKey, index, data)
				if err != nil {
					return 0, err
				} else {
					return uint64(index), nil
				}
			}
		}
	}

	numTags, err := redis.Uint64(c.Do("LLEN", tagKey))
	if err != nil {
		return 0, err
	}

	if numTags >= MAX_USER_TAGS {
		return 0, fmt.Errorf("Reach max tags")
	} else {
		// add brand new tag
		_, err = c.Do("RPUSH", tagKey, data)
		if err != nil {
			return 0, err
		} else {
			return numTags, nil
		}
	}
}

func dbUserTagExists(userID uint64, tagID uint64, c redis.Conn) (bool, error) {
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

func dbCheckSubTag(userID uint64, tagID uint64, c redis.Conn) (bool, error) {
	tagKey := GetTagKey(userID)

	// find empty tag
	tags, err := redis.Strings(c.Do("LRANGE", tagKey, 0, MAX_USER_TAGS))
	if err != nil {
		return false, err
	} else {
		for _, tag := range tags {
			if len(tag) != 0 {
				fatherID, _ := getTagInfo(tag)
				if fatherID == tagID {
					return true, nil
				}
			}
		}
	}

	return false, nil
}

func dbHasMember(userID uint64, tagID uint64, c redis.Conn) (bool, error) {
	contactsKey := GetContactsKey(userID)
	bit := uint64(^(1 << tagID))
	members, err := redis.Values(c.Do("SMEMBERS", contactsKey))
	if err != nil {
		return false, err
	} else {
		for _, member := range members {
			contact, err := redis.Uint64(member, err)
			if err != nil {
				return false, err
			}
			flag, err := getFlagDB(userID, contact, c)
			if err != nil {
				return false, err
			}
			if (flag | bit) != ZERO_64 {
				return true, nil
			}
		}
	}
	return false, nil
}

func dbRemTag(userID uint64, tagID uint64, c redis.Conn) error {
	if isSystemTag(tagID) {
		return fmt.Errorf("Invalid tag")
	}

	tagIdx := getUserTagIdx(tagID)
	tagKey := GetTagKey(userID)
	numTags, err := redis.Int(c.Do("LLEN", tagKey))
	if err != nil {
		return err
	}

	if int(tagIdx) < numTags {
		_, err = c.Do("LSET", tagKey, tagIdx, "")
		if err != nil {
			return err
		}
	} else {
		return fmt.Errorf("Remove tag out of range")
	}

	return nil
}
