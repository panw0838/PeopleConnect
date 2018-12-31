package user

import (
	"encoding/json"
	"fmt"

	"github.com/garyburd/redigo/redis"
)

const ONE_64 uint64 = 0x1
const ZERO_64 uint64 = 0x0

// system tab bits
const BLK_BIT uint64 = ONE_64 << (SYSTEM_TAG_OFFSET + 0)
const UDF_BIT uint64 = ONE_64 << (SYSTEM_TAG_OFFSET + 1)
const FML_BIT uint64 = ONE_64 << (SYSTEM_TAG_OFFSET + 2)
const CLM_BIT uint64 = ONE_64 << (SYSTEM_TAG_OFFSET + 3)
const CWK_BIT uint64 = ONE_64 << (SYSTEM_TAG_OFFSET + 4)
const FRD_BIT uint64 = ONE_64 << (SYSTEM_TAG_OFFSET + 5)

const SYSTEM_TAG_OFFSET uint64 = 32

// user define tag id
// from 32 - 63, 32 tags in total
const MAX_SYS_TAGS uint64 = 5
const MAX_USR_TAGS uint64 = 16

const USER_TAG_BITS uint64 = ((ONE_64 << MAX_USR_TAGS) - 1)

const FriendMask uint64 = (USER_TAG_BITS |
	UDF_BIT | FML_BIT | CLM_BIT | CWK_BIT | FRD_BIT)

type CustomTag struct {
	Father uint8  `json:"father"`
	Name   string `json:"name"`
	Index  uint8  `json:"idx,omitempty"`
}

type UserTags struct {
	Tags [MAX_USR_TAGS]CustomTag `json:"tags"`
}

func isValidSysTag(tagID uint8) bool {
	return tagID != 0 && uint64(tagID) <= MAX_SYS_TAGS
}

func getSysTagBit(tagID uint8) uint64 {
	return ONE_64 << (uint64(tagID) + SYSTEM_TAG_OFFSET)
}

func getUsrTagBit(tagID uint8) uint64 {
	return ONE_64 << tagID
}

func dbMoveTagMembers(input UpdateTagMemberInput, c redis.Conn) error {
	tags, err := dbGetUserTags(input.User, c)
	if err != nil {
		return err
	}

	if !input.SystemTag && tags.Tags[input.Tag].Father == 0 {
		return fmt.Errorf("Invalid tag")
	}

	var moveInBits uint64 = 0
	var moveOutBits uint64 = 0

	if input.SystemTag {
		tagBit := getSysTagBit(input.Tag)
		moveInBits = tagBit
		moveOutBits = tagBit
		for idx, subTag := range tags.Tags {
			if subTag.Father == input.Tag {
				moveOutBits |= getUsrTagBit(uint8(idx))
			}
		}
	} else {
		subTag := tags.Tags[input.Tag]
		tagBit := getUsrTagBit(input.Tag)
		moveInBits = tagBit | getSysTagBit(subTag.Father)
		moveOutBits = tagBit
	}

	for _, member := range input.Add {
		err := dbEnableBits(input.User, member, moveInBits, c)
		if err != nil {
			return err
		}
	}

	for _, member := range input.Rem {
		err := dbDisableBits(input.User, member, moveOutBits, c)
		if err != nil {
			return err
		}
	}

	return nil
}

func dbGetUserTags(uID uint64, c redis.Conn) (UserTags, error) {
	var tags UserTags
	userKey := GetAccountKey(uID)
	values, err := redis.Values(c.Do("HMGET", userKey, TagsField))
	if err != nil {
		return tags, err
	}

	if len(values) == 1 && values[0] != nil {
		bytes, err := redis.Bytes(values[0], err)
		if err != nil {
			return tags, err
		}
		if len(bytes) == 0 {
			return tags, nil
		}

		err = json.Unmarshal(bytes, &tags)
		if err != nil {
			return tags, err
		}
	}
	return tags, nil
}

func dbSetUserTags(uID uint64, tags UserTags, c redis.Conn) error {
	userKey := GetAccountKey(uID)
	bytes, err := json.Marshal(tags)
	if err != nil {
		return err
	}
	_, err = c.Do("HMSET", userKey, TagsField, bytes)
	return err
}

func dbAddTag(uID uint64, fID uint8, name string, c redis.Conn) (uint8, error) {
	tags, err := dbGetUserTags(uID, c)
	if err != nil {
		return 0, err
	}

	var foundIdx int = 0
	var foundEmpty bool = false

	for idx, tag := range tags.Tags {
		if tag.Father == 0 {
			foundEmpty = true
			foundIdx = idx
			break
		}
	}

	if foundEmpty {
		var tag CustomTag
		tag.Father = fID
		tag.Name = name
		tags.Tags[foundIdx] = tag
		return uint8(foundIdx), dbSetUserTags(uID, tags, c)
	} else {
		return 0, fmt.Errorf("Max tags reached")
	}
}

func dbRemTag(uID uint64, tagID uint8, c redis.Conn) error {
	if uint64(tagID) > MAX_USR_TAGS {
		return fmt.Errorf("Invalid tag")
	}

	tags, err := dbGetUserTags(uID, c)
	if err != nil {
		return err
	}

	tag := tags.Tags[tagID]
	if tag.Father == 0 {
		return fmt.Errorf("Invalid tag")
	}

	hasMember, err := dbTagHasMember(uID, tagID, c)
	if err != nil {
		return err
	}
	if hasMember {
		return fmt.Errorf("Tag has member")
	}

	tag.Father = 0
	tag.Name = ""
	tags.Tags[tagID] = tag
	return dbSetUserTags(uID, tags, c)
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
