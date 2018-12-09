package user

import (
	"fmt"
	"share"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const RelationCashSize uint64 = 0x4000000
const RelationMask uint64 = 0xffffffff0000003f
const ContactMask uint64 = 0xffffffff0000003e

var cash []Relation

type Relation struct {
	less  uint64
	more  uint64
	lFlag uint64
	mFlag uint64
}

func GetRelationKey(user1 uint64, user2 uint64) string {
	return "relate:" +
		strconv.FormatUint(user1, 10) + ":" +
		strconv.FormatUint(user2, 10)
}

func InitRelationCash() {
	cash = make([]Relation, RelationCashSize)
}

func GetLessMore(user1 uint64, user2 uint64) (uint64, uint64, error) {
	var less uint64
	var more uint64
	if user1 < user2 {
		less = user1
		more = user2
	} else if user1 > user2 {
		less = user2
		more = user1
	} else {
		return less, more, fmt.Errorf("self")
	}
	return less, more, nil
}

func GetRelation(less uint64, more uint64, c redis.Conn) (Relation, error) {
	idx := (less ^ more) & (RelationCashSize - share.ONE_64)
	relation := cash[idx]
	if relation.less != less || relation.more != more {
		relation.less = less
		relation.more = more
		lFlag, err := dbGetFlag(less, more, c)
		if err != nil {
			return relation, err
		}
		mFlag, err := dbGetFlag(more, less, c)
		if err != nil {
			return relation, err
		}
		relation.lFlag = lFlag
		relation.mFlag = mFlag
		cash[idx] = relation
	}
	return relation, nil
}

func ClearCashRelation(user1 uint64, user2 uint64) {
	idx := (user1 ^ user2) & (RelationCashSize - share.ONE_64)
	var relation Relation
	relation.less = 0
	relation.more = 0
	cash[idx] = relation
}

func IsFriendFlag(flag1 uint64, flag2 uint64) bool {
	return ((flag1 & ContactMask) != 0) && ((flag2 & ContactMask) != 0) && ((flag1 & BLK_BIT) == 0) && ((flag2 & BLK_BIT) == 0)
}

func IsFriend(user1 uint64, user2 uint64, c redis.Conn) (bool, error) {
	less, more, err := GetLessMore(user1, user2)
	if err != nil {
		return false, err
	}
	relation, err := GetRelation(less, more, c)
	if err != nil {
		return false, err
	}

	return IsFriendFlag(relation.lFlag, relation.mFlag), nil
}

func IsStrangerFlag(flag1 uint64, flag2 uint64) bool {
	return ((flag1 & RelationMask) == 0) && ((flag2 & RelationMask) == 0)
}

func IsStranger(uID uint64, cID uint64, c redis.Conn) (bool, error) {
	less, more, err := GetLessMore(uID, cID)
	if err != nil {
		return false, err
	}
	relation, err := GetRelation(less, more, c)
	if err != nil {
		return false, err
	}
	return IsStrangerFlag(relation.lFlag, relation.mFlag), nil
}

func IsBlacklistFlag(flag1 uint64, flag2 uint64) bool {
	return ((flag1 & BLK_BIT) != 0) && ((flag2 & BLK_BIT) != 0)
}

func IsBlacklist(uID uint64, cID uint64, c redis.Conn) (bool, error) {
	less, more, err := GetLessMore(uID, cID)
	if err != nil {
		return false, err
	}
	relation, err := GetRelation(less, more, c)
	if err != nil {
		return false, err
	}
	return IsBlacklistFlag(relation.lFlag, relation.mFlag), nil
}

func GetCashFlag(user1 uint64, user2 uint64, c redis.Conn) (uint64, uint64, error) {
	less, more, err := GetLessMore(user1, user2)
	if err != nil {
		return 0, 0, err
	}
	relation, err := GetRelation(less, more, c)
	if err != nil {
		return 0, 0, err
	}
	if less == user1 {
		return relation.lFlag, relation.mFlag, nil
	} else {
		return relation.mFlag, relation.lFlag, nil
	}
}

func dbEnableBits(user1 uint64, user2 uint64, bits uint64, c redis.Conn) error {
	ClearCashRelation(user1, user2)
	flag, err := dbGetFlag(user1, user2, c)
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
	ClearCashRelation(user1, user2)
	flag, err := dbGetFlag(user1, user2, c)
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
	relation, err := share.GetUint64(values[0], err)
	if err != nil {
		return 0, err
	}

	return relation, nil
}
