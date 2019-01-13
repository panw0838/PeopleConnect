package user

import (
	"fmt"
	"share"
	"strconv"
	"strings"

	"github.com/garyburd/redigo/redis"
)

const Max_Groups int = 3

type UserGroups struct {
	Groups []uint64 `json:"groups"`
}

func DbGetUserGroups(uID uint64, c redis.Conn) ([]int64, error) {
	userKey := GetAccountKey(uID)
	bytes, err := redis.Bytes(c.Do("HGET", userKey, GroupsFiled))
	if err != nil {
		return nil, err
	}

	var groups []int64
	groupStrs := strings.Split(string(bytes), ",")
	for _, str := range groupStrs {
		group, err := strconv.ParseInt(str, 10, 64)
		if err != nil {
			return nil, err
		}
		groups = append(groups, group)
	}

	return groups, nil
}

func DbSetUserGroups(uID uint64, groups []int64, c redis.Conn) error {
	var groupsStr = ""
	for idx, group := range groups {
		if idx == 0 {
			groupsStr += string(group)
		} else {
			groupsStr += "," + string(group)
		}
	}

	userKey := GetAccountKey(uID)
	_, err := c.Do("HSET", userKey, GroupsFiled, groupsStr)
	if err != nil {
		return err
	}

	return nil
}

func dbAddGroup(uID uint64, group int64, c redis.Conn) error {
	groups, err := DbGetUserGroups(uID, c)
	if err != nil {
		return err
	}

	if len(groups) >= Max_Groups {
		return fmt.Errorf("Reach max groups")
	}

	for _, gID := range groups {
		if gID == group {
			return fmt.Errorf("Already in group")
		}
	}

	// check if groups valid
	univKey := share.GetUnviKey()
	values, err := redis.Strings(c.Do("ZRANGEBYSCORE", univKey, group, group))
	if err != nil {
		return err
	}
	if len(values) == 0 {
		return fmt.Errorf("No such group")
	}
	if len(values) > 1 {
		return fmt.Errorf("Conflict groups")
	}

	groups = append(groups, group)
	err = DbSetUserGroups(uID, groups, c)

	return err
}

func dbGetGroupName(group int64, c redis.Conn) (string, error) {
	univKey := share.GetUnviKey()
	values, err := redis.Strings(c.Do("ZRANGEBYSCORE", univKey, group, group))
	if err != nil {
		return "", err
	}
	if len(values) == 0 {
		return "", fmt.Errorf("No such group")
	}
	if len(values) > 1 {
		return "", fmt.Errorf("Conflict groups")
	}
	return values[0], nil
}
