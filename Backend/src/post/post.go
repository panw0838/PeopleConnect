package post

import (
	"encoding/json"
	"fmt"
	"strconv"
	"user"

	"github.com/garyburd/redigo/redis"
)

type PostData struct {
	Desc  string   `json:"desc"`
	Flag  uint64   `json:"flag"`
	Time  string   `json:"time"`
	Files []string `json:"file"`
}

type PublishData struct {
	User  uint64   `json:"user"`
	Desc  string   `json:"desc"`
	Flag  uint64   `json:"flag"`
	Time  string   `json:"time"`
	Files []string `json:"file"`
}

func getPostKey(userID uint64) string {
	return "post:" + strconv.FormatUint(userID, 10)
}

func getPublishKey(uID uint64) string {
	return "fposts" + strconv.FormatUint(uID, 10)
}

func canSeePost(cFlag uint64, pFlag uint64) bool {
	return (cFlag & pFlag) != 0
}

func dbAddPost(uID uint64, pID uint64, data PostData, c redis.Conn) error {
	bytes, err := json.Marshal(data)
	if err != nil {
		return err
	}

	postKey := getPostKey(uID)
	_, err = c.Do("ZADD", postKey, pID, string(bytes))
	if err != nil {
		return err
	}
	return nil
}

func dbPublishPost(uID uint64, pID uint64, pFlag uint64, c redis.Conn) error {
	contactsKey := user.GetContactsKey(uID)
	contacts, err := redis.Strings(c.Do("SMEMBERS", contactsKey))
	if err != nil {
		return err
	}

	for _, contact := range contacts {
		cID, err := strconv.ParseUint(contact, 10, 64)
		if err != nil {
			return err
		}
		fpostsKey := getPublishKey(cID)
		cFlag, err := user.DbGetFlag(cID, uID, c)
		if err != nil {
			return err
		}
		if canSeePost(cFlag, pFlag) {
			publishStr := fmt.Sprintf("%d:%d", uID, pID)
			_, err := c.Do("ZADD", fpostsKey, pID, publishStr)
			if err != nil {
				return err
			}
		}
	}

	return nil
}

/*
func dbGetContactPosts(uID uint64, cID uint64, from uint64, to uint64, c redis.Conn) ([]PostData, []uint64, error) {
	postsKey := getPostKey(uID)
	c.Do("ZRANGE", postsKey, from, to, "WITHSCORES")
}
*/

func dbGetPublish(uID uint64, from uint64, to uint64, c redis.Conn) ([]PublishData, error) {
	var results []PublishData
	publishKey := getPublishKey(uID)
	publishes, err := redis.Strings(c.Do("ZRANGEBYSCORE", publishKey, from, to))
	if err != nil {
		return results, err
	}

	for _, publish := range publishes {
		var cID uint64
		var pID uint64
		fmt.Sscanf(publish, "%d:%d", &cID, &pID)
		postKey := getPostKey(cID)
		values, err := redis.Values(c.Do("ZRANGEBYSCORE", postKey, pID, pID))
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
			cFlag, err := user.DbGetFlag(cID, uID, c)
			if err != nil {
				return results, err
			}
			if canSeePost(cFlag, post.Flag) {
				var publish PublishData
				publish.User = cID
				publish.Flag = post.Flag
				publish.Desc = post.Desc
				publish.Time = post.Time
				publish.Files = post.Files
				results = append(results, publish)
			}
		}
	}

	return results, nil
}
