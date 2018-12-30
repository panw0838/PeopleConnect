package post

import (
	"encoding/json"
	"fmt"
	"share"
	"time"

	"github.com/garyburd/redigo/redis"
)

type Comment struct {
	From  uint64 `json:"from"`
	To    uint64 `json:"to"`
	Msg   string `json:"msg"`
	ID    uint64 `json:"id"`
	Group uint32 `json:"src"`
}

type CommentsData struct {
	Owner    uint64    `json:"user"`
	Post     uint64    `json:"post"`
	Comments []Comment `json:"cmts"`
}

func dbGetComments(oID uint64, pID uint64, uID uint64, src uint32, from uint64, c redis.Conn) ([]Comment, error) {
	cmtKey := share.GetPostCmtKey(oID, pID)
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

		canSee, err := canSeeComment(uID, oID, src, comment, c)
		if err != nil {
			return nil, err
		}
		if canSee {
			results = append(results, comment)
		}
	}

	return results, nil
}

func dbAddComment(input AddCmtInput, c redis.Conn) (uint64, error) {
	var comment Comment
	comment.From = input.UID
	comment.To = input.To
	comment.Msg = input.Msg
	comment.ID = share.GetTimeID(time.Now())
	comment.Group = input.Group
	bytes, err := json.Marshal(comment)
	if err != nil {
		return 0, err
	}

	cmtKey := share.GetPostCmtKey(input.PostOwner, input.PostID)
	_, err = c.Do("ZADD", cmtKey, comment.ID, bytes)
	if err != nil {
		return 0, err
	}

	return comment.ID, nil
}

func dbDelComment(input DelCmtInput, c redis.Conn) error {
	cmtKey := share.GetPostCmtKey(input.PostOwner, input.PostID)

	values, err := redis.Values(c.Do("ZRANGEBYSCORE", cmtKey, input.CmtID, input.CmtID))
	if err != nil {
		return err
	}

	for _, value := range values {
		cmtData, err := redis.Bytes(value, err)
		if err != nil {
			return err
		}
		var comment Comment
		err = json.Unmarshal(cmtData, &comment)
		if err != nil {
			return err
		}
		if comment.From == input.UID {
			_, err = c.Do("ZREM", cmtKey, value)
			if err != nil {
				return err
			}
		} else {
			return fmt.Errorf("Fail delete")
		}
	}

	return nil
}

func dbGetLike(uID uint64, oID uint64, pID uint64, c redis.Conn) (bool, error) {
	likeKey := share.GetPostLikeKey(oID, pID)
	like, err := redis.Int(c.Do("SISMEMBER", likeKey, uID))
	return (like == 1), err
}

func dbGetLikes(oID uint64, pID uint64, c redis.Conn) ([]int64, error) {
	likeKey := share.GetPostLikeKey(oID, pID)
	members, err := redis.Int64s(c.Do("SMEMBERS", likeKey))
	return members, err
}

func dbLikePost(uID uint64, oID uint64, pID uint64, like bool, c redis.Conn) error {
	likeKey := share.GetPostLikeKey(oID, pID)
	if like {
		_, err := c.Do("SADD", likeKey, uID)
		return err
	} else {
		_, err := c.Do("SREM", likeKey, uID)
		return err
	}
}
