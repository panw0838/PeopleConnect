package messege

import (
	"PeoConServer/user"

	"github.com/garyburd/redigo/redis"
)

type Relation struct {
	user1 uint64
	user2 uint64
	flag1 uint64
	flag2 uint64
}

var RelationHashSize uint64 = 0x40000000
var RelationHash []Relation = make([]Relation, RelationHashSize)

func IsFriend(relation Relation) bool {
	return (relation.flag1 != 0) && (relation.flag2 != 0) && ((relation.flag1 & user.BLK_BIT) == 0) && ((relation.flag2 & user.BLK_BIT) == 0)
}

func GetRelation(user1 uint64, user2 uint64, c redis.Conn) (Relation, error) {
	hashIdx := (user1 ^ user2) & (RelationHashSize - user.ONE_64)
	relation := RelationHash[hashIdx]
	less, more := user1, user2
	if user1 > user2 {
		less, more = user2, user1
	}
	if relation.user1 != less || relation.user2 != more {
		relation.user1 = less
		relation.user2 = more
		flag1, err := user.DbGetFlag(less, more, c)
		if err != nil {
			return relation, err
		}
		flag2, err := user.DbGetFlag(more, less, c)
		if err != nil {
			return relation, err
		}
		relation.flag1 = flag1
		relation.flag2 = flag2
		RelationHash[hashIdx] = relation
	}
	return relation, nil
}
