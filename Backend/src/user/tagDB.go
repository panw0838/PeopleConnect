package user

import (
	"fmt"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

func GetTagKey(userID uint64) string {
	return "tag:" + strconv.FormatUint(userID, 10)
}

func getTagInfo(tagString string) (uint8, string) {
	var data []byte = []byte(tagString)
	fatherID := uint8(data[0])
	tagName := string(data[1:])
	return fatherID, tagName
}

func getTagData(fatherID uint8, name string) string {
	var fatherData []byte = []byte{byte(fatherID)}
	var nameData []byte = []byte(name)
	return string(append(fatherData, nameData...))
}

func getTagAndFatherBits(userID uint64, tagID uint8, c redis.Conn) (uint64, error) {
	var bits uint64 = (1 << tagID)

	if isUserTag(tagID) {
		tagKey := GetTagKey(userID)
		tagIdx := getUserTagIdx(tagID)
		tagData, err := redis.String(c.Do("LINDEX", tagKey, tagIdx))
		if err != nil {
			return ZERO_64, err
		}
		fatherID, _ := getTagInfo(tagData)
		if !isValidMainTag(fatherID) {
			return ZERO_64, fmt.Errorf("Invalid father tag")
		}
		bits |= (1 << fatherID)
	}
	return bits, nil
}

func getTagAndSonsBits(userID uint64, tagID uint8, c redis.Conn) (uint64, error) {
	var bits uint64 = (1 << tagID)

	tagKey := GetTagKey(userID)
	tags, err := redis.Strings(c.Do("LRANGE", tagKey, 0, MAX_USER_TAGS))
	if err != nil {
		return 0, err
	}

	for index, tag := range tags {
		if len(tag) > 0 {
			fatherID, _ := getTagInfo(tag)
			if err != nil {
				return 0, err
			}
			if !isValidMainTag(fatherID) {
				return 0, fmt.Errorf("Invalid father tag")
			}
			if fatherID == tagID {
				sonID := uint8(index) + USER_TAG_START
				bits |= (1 << sonID)
			}
		}
	}

	return bits, nil
}

func dbAddTag(userID uint64, fatherID uint8, name string, c redis.Conn) (uint8, error) {
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
					return uint8(index), nil
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
			return uint8(numTags), nil
		}
	}
}

func dbUserTagExists(userID uint64, tagID uint8, c redis.Conn) (bool, error) {
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

func dbTagHasMember(userID uint64, tagID uint8, c redis.Conn) (bool, error) {
	contactsKey := GetContactsKey(userID)
	bit := (ONE_64 << tagID)
	members, err := redis.Values(c.Do("SMEMBERS", contactsKey))
	if err != nil {
		return false, err
	} else {
		for _, member := range members {
			contact, err := redis.Uint64(member, err)
			if err != nil {
				return false, err
			}
			flag, _, err := GetCashFlag(userID, contact, c)
			if err != nil {
				return false, err
			}
			if (flag & bit) != ZERO_64 {
				return true, nil
			}
		}
	}
	return false, nil
}

func dbRemTag(userID uint64, tagID uint8, c redis.Conn) error {
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

func dbGetTags(userID uint64, c redis.Conn) ([]TagInfo, error) {
	var tagsInfo []TagInfo
	tagsKey := GetTagKey(userID)
	numTags, err := redis.Int(c.Do("LLEN", tagsKey))
	if err != nil {
		return nil, err
	}

	if numTags > 0 {
		tags, err := redis.Strings(c.Do("LRANGE", tagsKey, 0, numTags))
		if err != nil {
			return nil, err
		}

		for idx, tag := range tags {
			if len(tag) != 0 {
				var newTag TagInfo
				fatherID, name := getTagInfo(tag)
				newTag.TagID = uint8(idx) + USER_TAG_START
				newTag.FatherID = uint8(fatherID)
				newTag.TagName = name
				tagsInfo = append(tagsInfo, newTag)
			}
		}
	}

	return tagsInfo, nil
}
