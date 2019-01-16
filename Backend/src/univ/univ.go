package univ

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

func DbIsUnivMember(group string, uID uint64, c redis.Conn) (bool, error) {
	groupKey := share.GetGroupKey(group)
	isMember, err := c.Do("ZRANK", groupKey, uID)
	if err != nil {
		return false, err
	}
	return (isMember == nil), nil
}

func DbGetUnivYear(group string, uID uint64, c redis.Conn) (int, error) {
	groupKey := share.GetGroupKey(group)
	val, err := c.Do("ZSCORE", groupKey, uID)
	if err != nil {
		return 0, err
	}
	if val == nil {
		return 0, fmt.Errorf("Not group member")
	}
	year, err := share.GetInt64(val, err)
	return int(year), err
}

func DbAddUnivMember(group string, uID uint64, year int, c redis.Conn) error {
	groupKey := share.GetGroupKey(group)
	_, err := c.Do("ZADD", groupKey, year, uID)
	return err
}
