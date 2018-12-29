package post

import (
	"encoding/json"
	"group"
	"strconv"
	"user"

	"github.com/garyburd/redigo/redis"
)

type PostData struct {
	Owner    uint64    `json:"user,omitempty"`
	ID       uint64    `json:"id"`
	Content  string    `json:"cont"`
	Flag     uint64    `json:"flag"`
	X        float64   `json:"x"`
	Y        float64   `json:"y"`
	Files    []string  `json:"file,omitempty"`
	Nearby   bool      `json:"near,omitempty"`
	Groups   []uint32  `json:"group,omitempty"`
	Comments []Comment `json:"cmt,omitempty"`
}

func getPostKey(userID uint64) string {
	return "post:" + strconv.FormatUint(userID, 10)
}

func dbAddPost(uID uint64, data PostData, c redis.Conn) error {
	bytes, err := json.Marshal(data)
	if err != nil {
		return err
	}

	postKey := getPostKey(uID)
	_, err = c.Do("ZADD", postKey, data.ID, string(bytes))
	if err != nil {
		return err
	}

	return nil
}

func dbDelPost(uID uint64, pID uint64, c redis.Conn) error {
	postKey := getPostKey(uID)
	cmtKey := getCommentKey(uID, pID)
	_, err := c.Do("DEL", cmtKey)
	if err != nil {
		return err
	}
	_, err = c.Do("ZREMRANGEBYSCORE", postKey, pID, pID)
	return err
}

func dbGetPost(oID uint64, pID uint64, c redis.Conn) (bool, PostData, error) {
	var post PostData
	postKey := getPostKey(oID)
	values, err := redis.Values(c.Do("ZRANGEBYSCORE", postKey, pID, pID))
	if err != nil {
		return false, post, err
	}
	if len(values) == 0 {
		return false, post, nil
	}
	data, err := redis.Bytes(values[0], err)
	if err != nil {
		return false, post, err
	}

	err = json.Unmarshal(data, &post)
	if err != nil {
		return false, post, err
	}

	post.Owner = oID
	return true, post, nil
}

func dbGetSelfPosts(uID uint64, from uint64, to uint64, c redis.Conn) ([]PostData, error) {
	postsKey := getPostKey(uID)
	values, err := redis.Values(c.Do("ZRANGEBYSCORE", postsKey, from, to))
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

		post.Owner = uID
		comments, err := dbGetComments(uID, post.ID, uID, AllGroups, 0, c)
		if err != nil {
			return nil, err
		}
		post.Comments = comments
		results = append(results, post)
	}

	return results, nil
}

func dbGetUserPosts(uID uint64, cID uint64, from uint64, to uint64, c redis.Conn) ([]PostData, error) {
	uFlag, cFlag, err := user.GetCashFlag(uID, cID, c)
	if err != nil {
		return nil, err
	}

	if user.IsBlacklistFlag(uFlag, cFlag) {
		return nil, nil
	}

	isFriend := user.IsFriendFlag(uFlag, cFlag)
	isStranger := user.IsStrangerFlag(uFlag, cFlag)

	postsKey := getPostKey(cID)
	values, err := redis.Values(c.Do("ZRANGEBYSCORE", postsKey, from, to))
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

		post.Owner = cID
		var canSee = false

		// check friend posts
		if isFriend && PostVisibleForFriend(cFlag, post.Flag) {
			canSee = true
		}
		// check stranger posts
		if !canSee && isStranger && post.Nearby {
			canSee = true
		}
		// check group posts
		if !canSee && len(post.Groups) > 0 {
			for _, gID := range post.Groups {
				isMember, err := group.DbIsGroupMember(gID, uID, c)
				if err != nil {
					return results, err
				}
				if isMember {
					canSee = true
					break
				}
			}
		}

		// no comments for user posts
		if canSee {
			results = append(results, post)
		}
	}

	return results, nil
}
