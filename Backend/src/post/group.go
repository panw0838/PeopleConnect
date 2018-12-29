package post

import (
	"share"
	"user"

	"github.com/garyburd/redigo/redis"
)

// uID already checked
func dbVisibleInGroup(gID uint32, uID uint64, cID uint64, c redis.Conn) (bool, error) {
	groupKey := share.GetGroupKey(gID)

	isMember, err := redis.Int(c.Do("SISMEMBER", groupKey, cID))
	if err != nil {
		return false, err
	}
	visible := (isMember == 1)
	if visible {
		isBlack, err := user.IsBlacklist(uID, cID, c)
		if err != nil {
			return false, err
		}
		visible = !isBlack
	}
	return visible, nil
}

func dbGetUserGroups(uID uint64, c redis.Conn) ([]uint32, error) {
	var result []uint32

	groupKey := share.GetUserGroupKey(uID)
	values, err := redis.Values(c.Do("SMEMBERS", groupKey))
	if err != nil {
		return nil, err
	}

	for _, value := range values {
		group, err := redis.Uint64(value, err)
		if err != nil {
			return nil, err
		}
		result = append(result, uint32(group))
	}

	return result, nil
}

func inSameGroup(groups1 []uint32, groups2 []uint32) bool {
	for _, group1 := range groups1 {
		for _, group2 := range groups2 {
			if group1 == group2 {
				return true
			}
		}
	}
	return false
}
