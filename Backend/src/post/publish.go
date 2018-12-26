package post

import (
	"encoding/json"
	"fmt"
	"share"
	"strconv"
	"user"

	"github.com/garyburd/redigo/redis"
)

func getFPubKey(uID uint64) string {
	return "fposts:" + strconv.FormatUint(uID, 10)
}

func getGPubKey(gID uint32) string {
	return "gposts:" + strconv.FormatUint(uint64(gID), 10)
}

func getNearKey(geoID uint64) string {
	return "near_post:" + strconv.FormatUint(geoID, 10)
}

func dbPublishPost(uID uint64, post PostData, c redis.Conn) error {
	publishStr := fmt.Sprintf("%d:%d", uID, post.ID)

	contactsKey := user.GetContactsKey(uID)
	contacts, err := redis.Strings(c.Do("SMEMBERS", contactsKey))
	if err != nil {
		return err
	}

	// add to friends timeline
	if PostForFriend(post.Flag) {
		for _, contact := range contacts {
			cID, err := strconv.ParseUint(contact, 10, 64)
			if err != nil {
				return err
			}
			fpostsKey := getFPubKey(cID)
			canSee, err := friendPost(cID, uID, post.Flag, c)
			if err != nil {
				return err
			}
			if canSee {
				_, err := c.Do("ZADD", fpostsKey, post.ID, publishStr)
				if err != nil {
					return err
				}
			}
		}
	}

	// add to group timeline
	for _, group := range post.Groups {
		groupKey := getGPubKey(group)
		_, err := c.Do("ZADD", groupKey, post.ID, publishStr)
		if err != nil {
			return err
		}
	}

	// add to nearby timeline
	if post.Nearby {
		geoID := share.GetGeoID(post.X, post.Y)
		nearKey := getNearKey(geoID)
		_, err := c.Do("ZADD", nearKey, post.ID, publishStr)
		if err != nil {
			return err
		}
	}

	// add to self timeline
	fpostsKey := getFPubKey(uID)
	_, err = c.Do("ZADD", fpostsKey, post.ID, publishStr)
	if err != nil {
		return err
	}

	return nil
}

func dbGetPublish(uID uint64, pubLvl uint8, key string, from uint64, to uint64, c redis.Conn) ([]PostData, error) {
	publishes, err := redis.Strings(c.Do("ZRANGEBYSCORE", key, from, to))
	if err != nil {
		return nil, err
	}

	var results []PostData
	for _, publish := range publishes {
		var cID uint64
		var pID uint64
		fmt.Sscanf(publish, "%d:%d", &cID, &pID)
		postKey := getPostKey(cID)
		values, err := redis.Values(c.Do("ZRANGEBYSCORE", postKey, pID, pID))
		for _, value := range values {
			data, err := redis.Bytes(value, err)
			if err != nil {
				return nil, err
			}

			var post PostData
			err = json.Unmarshal(data, &post)
			if err != nil {
				return nil, err
			}

			post.Owner = cID
			canSee, err := canSeePost(pubLvl, uID, cID, post.Flag, c)
			if err != nil {
				return nil, err
			}

			if canSee {
				// get comments
				cmtsKey := getCommentKey(cID, post.ID)
				comments, err := dbGetComments(cmtsKey, pubLvl, uID, 0, c)
				if err != nil {
					return nil, err
				}
				post.Comments = comments
				results = append(results, post)
			}
		}
	}

	return results, nil
}

func dbGetNearbyPublish(input SyncNearbyPostsInput, from uint64, to uint64, c redis.Conn) ([]PostData, error) {
	var results []PostData
	geoID := share.GetGeoID(input.X, input.Y)
	for pos := geoID - 3; pos <= geoID+3; pos++ {
		nearKey := getNearKey(pos)
		publishes, err := redis.Strings(c.Do("ZRANGEBYSCORE", nearKey, from, to))
		if err != nil {
			return nil, err
		}

		for _, publish := range publishes {
			var cID uint64
			var pID uint64
			fmt.Sscanf(publish, "%d:%d", &cID, &pID)
			postKey := getPostKey(cID)
			values, err := redis.Values(c.Do("ZRANGEBYSCORE", postKey, pID, pID))
			for _, value := range values {
				data, err := redis.Bytes(value, err)
				if err != nil {
					return nil, err
				}

				var post PostData
				err = json.Unmarshal(data, &post)
				if err != nil {
					return nil, err
				}

				post.Owner = cID
				canSee, err := canSeePost(PubLvl_Stranger, input.User, cID, post.Flag, c)
				if err != nil {
					return nil, err
				}

				if canSee {
					// get comments
					cmtsKey := getCommentKey(cID, post.ID)
					comments, err := dbGetComments(cmtsKey, PubLvl_Stranger, input.User, 0, c)
					if err != nil {
						return nil, err
					}
					post.Comments = comments
					results = append(results, post)
				}
			}
		}
	}
	return results, nil
}
