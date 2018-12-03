package post

import (
	"encoding/json"
	"time"

	"github.com/garyburd/redigo/redis"
)

type CommentInput struct {
	User  uint64 `json:"user"`
	Owner uint64 `json:"owner"`
	Post  uint64 `json:"post"`
	Reply uint32 `json:"reply"`
	Msg   string `json:"msg"`
}

type Comment struct {
	From  uint64 `json:"from"`
	Reply uint32 `json:"reply"`
	Msg   string `json:"msg"`
	Time  string `json:"time,omitempty"`
}

func dbCommentPost(input CommentInput, c redis.Conn) error {
	var comment Comment
	comment.From = input.User
	comment.Reply = input.Reply
	comment.Msg = input.Msg
	comment.Time = time.Now().Format(time.RFC3339)
	bytes, err := json.Marshal(comment)
	if err != nil {
		return err
	}

	cmtKey := getCommentKey(input.Owner, input.Post)
	_, err = c.Do("RPUSH", cmtKey, bytes)
	if err != nil {
		return err
	}

	return nil
}

type GetCommentsInput struct {
	User  uint64 `json:"user"`
	Owner uint64 `json:"owner"`
	Post  uint64 `json:"post"`
	Start uint32 `json:"start"`
}

func dbGetPostComments(input GetCommentsInput, c redis.Conn) ([]Comment, error) {
	var results []Comment
	cmtKey := getCommentKey(input.Owner, input.Post)
	numCmts, err := redis.Int(c.Do("LLEN", cmtKey))
	if err != nil {
		return nil, err
	}

	values, err := redis.Values(c.Do("LRANGE", cmtKey, input.Start, numCmts))
	if err != nil {
		return nil, err
	}

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
