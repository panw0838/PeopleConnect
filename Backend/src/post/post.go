package post

import (
	"encoding/json"
	"strconv"
	"user"

	"github.com/garyburd/redigo/redis"
)

type PostData struct {
	Owner    uint64    `json:"user,omitempty"`
	ID       uint64    `json:"id"`
	Content  string    `json:"cont"`
	Flag     uint64    `json:"flag"`
	X        float32   `json:"x"`
	Y        float32   `json:"y"`
	Files    []string  `json:"file,omitempty"`
	Groups   []int     `json:"group,omitempty"`
	Comments []Comment `json:"cmt,omitempty"`
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

func dbGetSelfPosts(uID uint64, from uint64, to uint64, c redis.Conn) ([]PostData, error) {
	postsKey := getPostKey(uID)
	values, err := redis.Values(c.Do("ZRANGE", postsKey, from, to))
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
		cmtsKey := getCommentKey(uID, post.ID)
		comments, err := dbGetComments(cmtsKey, PubLvl_Self, uID, 0, -1, c)
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

	groups, err := dbGetGroups(uID, c)
	if err != nil {
		return nil, err
	}

	postsKey := getPostKey(cID)
	values, err := redis.Values(c.Do("ZRANGE", postsKey, from, to))
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
		if isFriend && friendPostFlag(cFlag, post.Flag) {
			canSee = true
		}
		// check public posts
		if !canSee && len(groups) > 0 && len(post.Groups) > 0 {
			if inSameGroup(groups, post.Groups) {
				canSee = true
			}
		}
		// check stranger posts
		if !canSee && isStranger && PostForStranger(post.Flag) {
			canSee = true
		}

		// no comments for user posts
		if canSee {
			results = append(results, post)
		}
	}

	return results, nil
}
