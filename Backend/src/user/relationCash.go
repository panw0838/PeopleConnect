package user

import (
	"fmt"
	"share"

	"github.com/garyburd/redigo/redis"
)

const RelationCashSize uint64 = 0x4000000

var cash []Relation

type Relation struct {
	less  uint64
	more  uint64
	lFlag uint64
	mFlag uint64
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

func IsFriend(user1 uint64, user2 uint64, c redis.Conn) (bool, error) {
	less, more, err := GetLessMore(user1, user2)
	if err != nil {
		return false, err
	}
	relation, err := GetRelation(less, more, c)
	if err != nil {
		return false, err
	}

	return ((relation.lFlag != 0) &&
		(relation.mFlag != 0) &&
		((relation.lFlag & BLK_BIT) == 0) &&
		((relation.mFlag & BLK_BIT) == 0)), nil
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
	return (relation.lFlag == 0) && (relation.mFlag == 0), nil
}

func GetCashFlag(user1 uint64, user2 uint64, c redis.Conn) (uint64, error) {
	less, more, err := GetLessMore(user1, user2)
	if err != nil {
		return 0, err
	}
	relation, err := GetRelation(less, more, c)
	if err != nil {
		return 0, err
	}
	if less == user1 {
		return relation.lFlag, nil
	} else {
		return relation.mFlag, nil
	}
}
