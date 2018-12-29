package group

import (
	"share"

	"github.com/garyburd/redigo/redis"
)

func DbIsGroupMember(gID uint32, uID uint64, c redis.Conn) (bool, error) {
	groupKey := share.GetGroupKey(gID)
	isMember, err := redis.Int(c.Do("SISMEMBER", groupKey, uID))
	if err != nil {
		return false, err
	}
	return (isMember == 1), nil
}
