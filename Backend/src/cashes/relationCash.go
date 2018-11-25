package cash

import (
	"share"
	"user"

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

func IsFriend(relation Relation) bool {
	return (relation.lFlag != 0) && (relation.mFlag != 0) &&
		((relation.lFlag & user.BLK_BIT) == 0) &&
		((relation.mFlag & user.BLK_BIT) == 0)
}

func GetRelation(less uint64, more uint64, c redis.Conn) (Relation, error) {
	idx := (less ^ more) & (RelationCashSize - share.ONE_64)
	relation := cash[idx]
	if relation.less != less || relation.more != more {
		relation.less = less
		relation.more = more
		lFlag, err := user.DbGetFlag(less, more, c)
		if err != nil {
			return relation, err
		}
		mFlag, err := user.DbGetFlag(more, less, c)
		if err != nil {
			return relation, err
		}
		relation.lFlag = lFlag
		relation.mFlag = mFlag
		cash[idx] = relation
	}
	return relation, nil
}
