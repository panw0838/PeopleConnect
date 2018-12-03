package post

import (
	"encoding/json"
	"fmt"

	"github.com/garyburd/redigo/redis"
)

func dbPublishGroupPost(uID uint64, groups []uint64, pID uint64, pFlag uint64, c redis.Conn) error {
	for _, group := range groups {
		groupKey := getGroupKey(group)
		publishStr := fmt.Sprintf("%d:%d", uID, pID)
		_, err := c.Do("ZADD", groupKey, pID, publishStr)
		if err != nil {
			return err
		}
	}

	return nil
}

func dbGetGroupPosts(uID uint64, gID uint64, pIdx int, c redis.Conn) ([]PostData, error) {
	groupKey := getGroupKey(gID)
	if pIdx == 0 {
		num, err := redis.Int(c.Do("ZCARD", groupKey))
		if err != nil {
			return nil, err
		}
		pIdx = num
	}

	end := pIdx - 1
	start := end - 10
	if start < 0 {
		start = 0
	}
	if end < 0 {
		return nil, nil
	}

	values, err := redis.Values(c.Do("ZRANGE", groupKey, start, end))
	if err != nil {
		return nil, err
	}

	var results []PostData
	for _, value := range values {
		postData, err := redis.Bytes(value, err)
		if err != nil {
			return results, err
		}
		var post PostData
		err = json.Unmarshal(postData, &post)
		if err != nil {
			return results, err
		}

		post.User = uID
		results = append(results, post)
	}

	return results, nil
}
