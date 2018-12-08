package post

import (
	"encoding/json"
	"share"
	"strconv"
	"time"

	"github.com/garyburd/redigo/redis"
)

type Comment struct {
	From  uint64 `json:"from"`
	Reply uint16 `json:"reply"`
	Msg   string `json:"msg"`
	Time  uint64 `json:"time,omitempty"`
}

func getCommentKey(uID uint64, pID uint64) string {
	return "cmt:" + strconv.FormatUint(uID, 10) + ":" + strconv.FormatUint(pID, 10)
}

func dbGetComments(cmtKey string, from int, to int, c redis.Conn) ([]Comment, error) {
	numCmts, err := redis.Int(c.Do("LLEN", cmtKey))
	if err != nil {
		return nil, err
	}

	if numCmts < from {
		return nil, nil
	}

	values, err := redis.Values(c.Do("LRANGE", cmtKey, from, to))
	if err != nil {
		return nil, err
	}

	var results []Comment
	for _, value := range values {
		cmtData, err := redis.Bytes(value, err)
		if err != nil {
			return nil, err
		}
		var comment Comment
		err = json.Unmarshal(cmtData, &comment)
		if err != nil {
			return nil, err
		}
		results = append(results, comment)
	}

	return results, nil

}

func dbCommentPost(input CommentInput, c redis.Conn) (int, []Comment, error) {
	var comment Comment
	comment.From = input.User
	comment.Reply = input.Reply
	comment.Msg = input.Msg
	comment.Time = share.GetTimeID(time.Now())
	bytes, err := json.Marshal(comment)
	if err != nil {
		return 0, nil, err
	}

	cmtKey := getCommentKey(input.Owner, input.Post)
	idx, err := redis.Int(c.Do("RPUSH", cmtKey, bytes))
	if err != nil {
		return 0, nil, err
	}

	if idx > input.Last+1 {
		comments, err := dbGetComments(cmtKey, input.Last, idx-1, c)
		if err != nil {
			return 0, nil, err
		}
		return idx, comments, nil
	}

	return 0, nil, nil
}
