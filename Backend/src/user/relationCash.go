package user

import (
	"github.com/garyburd/redigo/redis"
)

type Relation struct {
	less  uint64
	more  uint64
	lFlag uint64
	mFlag uint64
}

var RelationCashSize uint64 = 0x4000000
var RelationCash []Relation = make([]Relation, RelationCashSize)

func IsFriend(relation Relation) bool {
	return (relation.lFlag != 0) && (relation.mFlag != 0) &&
		((relation.lFlag & BLK_BIT) == 0) && ((relation.mFlag & BLK_BIT) == 0)
}

func GetRelation(less uint64, more uint64, c redis.Conn) (Relation, error) {
	idx := (less ^ more) & (RelationCashSize - ONE_64)
	relation := RelationCash[idx]
	if relation.less != less || relation.more != more {
		relation.less = less
		relation.more = more
		lFlag, err := DbGetFlag(less, more, c)
		if err != nil {
			return relation, err
		}
		mFlag, err := DbGetFlag(more, less, c)
		if err != nil {
			return relation, err
		}
		relation.lFlag = lFlag
		relation.mFlag = mFlag
		RelationCash[idx] = relation
	}
	return relation, nil
}
