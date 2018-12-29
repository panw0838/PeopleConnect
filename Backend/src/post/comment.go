package post

import (
	"encoding/json"
	"fmt"
	"share"
	"strconv"
	"time"

	"github.com/garyburd/redigo/redis"
)

type Comment struct {
	From uint64 `json:"from"`
	To   uint64 `json:"to"`
	Msg  string `json:"msg"`
	ID   uint64 `json:"id"`
}

type CommentsData struct {
	Owner    uint64    `json:"user"`
	Post     uint64    `json:"post"`
	Comments []Comment `json:"cmts"`
}

func getCommentKey(uID uint64, pID uint64) string {
	return "cmt:" + strconv.FormatUint(uID, 10) + ":" + strconv.FormatUint(pID, 10)
}

func dbGetComments(cmtKey string, uID uint64, src uint32, from uint64, c redis.Conn) ([]Comment, error) {
	values, err := redis.Values(c.Do("ZRANGEBYSCORE", cmtKey, from, share.MAX_TIME))
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
		canSee, err := canSeeComment(uID, src, comment.From, comment.To, c)
		if err != nil {
			return nil, err
		}
		if canSee {
			results = append(results, comment)
		}
	}

	return results, nil
}

func dbAddComment(input AddCmtInput, c redis.Conn) (uint64, []Comment, error) {
	var comment Comment
	comment.From = input.UID
	comment.To = input.To
	comment.Msg = input.Msg
	comment.ID = share.GetTimeID(time.Now())
	bytes, err := json.Marshal(comment)
	if err != nil {
		return 0, nil, err
	}

	cmtKey := getCommentKey(input.PostOwner, input.PostID)
	comments, err := dbGetComments(cmtKey, input.UID, input.Source, input.LastCmt+1, c)
	if err != nil {
		return 0, nil, err
	}

	_, err = c.Do("ZADD", cmtKey, comment.ID, bytes)
	if err != nil {
		return 0, nil, err
	}

	return comment.ID, comments, nil
}

func dbDelComment(input DelCmtInput, c redis.Conn) ([]Comment, error) {
	cmtKey := getCommentKey(input.PostOwner, input.PostID)
	comments, err := dbGetComments(cmtKey, input.UID, input.Source, input.LastCmt+1, c)
	if err != nil {
		return nil, err
	}

	values, err := redis.Values(c.Do("ZRANGEBYSCORE", cmtKey, input.CmtID, input.CmtID))
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
		if comment.From == input.UID {
			_, err = c.Do("ZREM", cmtKey, value)
			if err != nil {
				return nil, err
			}
		} else {
			return nil, fmt.Errorf("Fail delete")
		}
	}

	return comments, nil
}
