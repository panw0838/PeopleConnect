package post

import (
	"encoding/json"
	"share"
	"strconv"
	"time"
	"user"

	"github.com/garyburd/redigo/redis"
)

type Comment struct {
	From  uint64 `json:"from"`
	To    uint64 `json:"to"`
	Index uint16 `json:"idx,imitempty"`
	Reply uint16 `json:"re"`
	Msg   string `json:"msg"`
	Time  uint64 `json:"time,omitempty"`
}

type CommentsData struct {
	Owner    uint64    `json:"user"`
	Post     uint64    `json:"post"`
	Comments []Comment `json:"cmts"`
}

func getCommentKey(uID uint64, pID uint64) string {
	return "cmt:" + strconv.FormatUint(uID, 10) + ":" + strconv.FormatUint(pID, 10)
}

func friendComment(uID uint64, from uint64, to uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != from {
		isFriend, err := user.IsFriend(from, uID, c)
		if err != nil {
			return false, err
		}
		canSee = isFriend
	}

	if canSee && to != 0 && uID != to {
		isFriend, err := user.IsFriend(to, uID, c)
		if err != nil {
			return false, err
		}
		canSee = isFriend
	}

	return canSee, nil
}

func strangerComment(uID uint64, from uint64, to uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != from {
		isStranger, err := user.IsStranger(from, uID, c)
		if err != nil {
			return false, err
		}
		canSee = isStranger
	}

	if canSee && to != 0 && uID != to {
		isStranger, err := user.IsStranger(to, uID, c)
		if err != nil {
			return false, err
		}
		canSee = isStranger
	}

	return canSee, nil
}

func publicComment(uID uint64, from uint64, to uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != from {
		isBlack, err := user.IsBalcklist(from, uID, c)
		if err != nil {
			return false, err
		}
		canSee = !isBlack
	}

	if canSee && to != 0 && uID != to {
		isBlack, err := user.IsBalcklist(to, uID, c)
		if err != nil {
			return false, err
		}
		canSee = !isBlack
	}

	return canSee, nil
}

func canSeeComment(uID uint64, pubLvl uint8, from uint64, to uint64, c redis.Conn) (bool, error) {
	if pubLvl == PubLvl_Friend {
		// friends publish
		return friendComment(uID, from, to, c)
	} else if pubLvl == PubLvl_Group {
		// group publish
		return publicComment(uID, from, to, c)
	} else if pubLvl == PubLvl_Stranger {
		// stranger publish
		return strangerComment(uID, from, to, c)
	}
	return false, nil
}

func dbGetComments(cmtKey string, pubLvl uint8, uID uint64, from int, to int, c redis.Conn) ([]Comment, error) {
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
	for idx, value := range values {
		cmtData, err := redis.Bytes(value, err)
		if err != nil {
			return nil, err
		}
		var comment Comment
		comment.Index = uint16(idx)
		err = json.Unmarshal(cmtData, &comment)
		if err != nil {
			return nil, err
		}
		canSee, err := canSeeComment(uID, pubLvl, comment.From, comment.To, c)
		if err != nil {
			return nil, err
		}
		if canSee {
			results = append(results, comment)
		}
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
		comments, err := dbGetComments(cmtKey, input.PubLvl, input.User, input.Last, idx-1, c)
		if err != nil {
			return 0, nil, err
		}
		return idx - 1, comments, nil
	}

	return 0, nil, nil
}
