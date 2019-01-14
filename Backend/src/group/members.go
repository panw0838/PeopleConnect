package group

import (
	"fmt"
	"share"

	"github.com/garyburd/redigo/redis"
)

func GetUnivName(uID uint64, c redis.Conn) (string, error) {
	univKey := share.GetUnviKey()
	values, err := redis.Strings(c.Do("ZRANGE", univKey, uID, uID))
	if err != nil {
		return "", err
	}
	if len(values) == 0 {
		return "", fmt.Errorf("not exist group")
	}
	if len(values) > 1 {
		return "", fmt.Errorf("more than 2 groups share id %d", uID)
	}
	return values[0], nil
}

func DbIsGroupMember(group string, uID uint64, c redis.Conn) (bool, error) {
	groupKey := share.GetGroupKey(group)
	isMember, err := redis.Int(c.Do("SISMEMBER", groupKey, uID))
	if err != nil {
		return false, err
	}
	return (isMember == 1), nil
}
