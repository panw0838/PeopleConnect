package post

import (
	"strconv"

	"github.com/garyburd/redigo/redis"
)

func getGroupKey(uID uint64) string {
	return "group:" + strconv.FormatUint(uID, 10)
}

func dbGetGroups(uID uint64, c redis.Conn) ([]uint32, error) {
	var result []uint32

	groupKey := getGroupKey(uID)
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
