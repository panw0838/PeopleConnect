package post

import (
	"encoding/json"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

type PostData struct {
	Desc  string   `json:"desc"`
	Flag  uint64   `json:"flag"`
	Time  string   `json:"time"`
	Files []string `json:"file"`
}

func getPostKey(userID uint64) string {
	return "post:" + strconv.FormatUint(userID, 10)
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
