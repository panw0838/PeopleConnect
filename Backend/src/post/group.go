package post

import (
	"strconv"

	"github.com/garyburd/redigo/redis"
)

func getGroupKey(uID uint64) string {
	return "group:" + strconv.FormatUint(uID, 10)
}

func dbGetGroups(uID uint64, c redis.Conn) ([]int, error) {
	var result []int

	groupKey := getGroupKey(uID)
	values, err := redis.Values(c.Do("SMEMBERS", groupKey))
	if err != nil {
		return nil, err
	}

	for _, value := range values {
		group, err := redis.Int(value, err)
		if err != nil {
			return nil, err
		}
		result = append(result, group)
	}

	return result, nil
}

func inSameGroup(groups1 []int, groups2 []int) bool {
	for _, group1 := range groups1 {
		for _, group2 := range groups2 {
			if group1 == group2 {
				return true
			}
		}
	}
	return false
}
