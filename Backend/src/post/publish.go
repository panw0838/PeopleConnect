package post

import (
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
	return "nposts:" + strconv.FormatUint(geoID, 10)
}

func dbPublishPost(uID uint64, post PostData, c redis.Conn) error {
	publishStr := fmt.Sprintf("%d:%d", uID, post.ID)

	// add to friends timeline
	if (post.Flag & user.FriendMask) != 0 {
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
			canSee, err := friendPost(cID, uID, post.Flag, c)
			if err != nil {
				return err
			}
			if canSee {
				fpostsKey := getFPubKey(cID)
				_, err := c.Do("ZADD", fpostsKey, post.ID, publishStr)
				if err != nil {
					return err
				}
			}
		}

		// add to self friend publish
		selfKey := getFPubKey(uID)
		_, err = c.Do("ZADD", selfKey, post.ID, publishStr)
		if err != nil {
			return err
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

	return nil
}

func dbGetFriendPublish(uID uint64, from uint64, to uint64, c redis.Conn) ([]PostData, error) {
	key := getFPubKey(uID)
	publishes, err := redis.Strings(c.Do("ZRANGEBYSCORE", key, from, to))
	if err != nil {
		return nil, err
	}

	var results []PostData
	for _, publish := range publishes {
		var oID uint64
		var pID uint64
		fmt.Sscanf(publish, "%d:%d", &oID, &pID)
		post, err := dbGetPost(oID, pID, c)
		if err != nil {
			return nil, err
		}
		// get friends comments
		post.Comments, err = dbGetComments(oID, post.ID, uID, FriendGroup, 0, c)
		if err != nil {
			return nil, err
		}
		results = append(results, post)
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
			var oID uint64
			var pID uint64
			fmt.Sscanf(publish, "%d:%d", &oID, &pID)

			if input.User != oID {
				isStranger, err := user.IsStranger(input.User, oID, c)
				if err != nil {
					return nil, err
				}
				if !isStranger {
					continue
				}
			}

			post, err := dbGetPost(oID, pID, c)
			if err != nil {
				return nil, err
			}

			// get strangers comments
			post.Comments, err = dbGetComments(oID, post.ID, input.User, StrangerGroup, 0, c)
			if err != nil {
				return nil, err
			}
			results = append(results, post)
		}
	}
	return results, nil
}

func dbGetGroupPublish(uID uint64, gID uint32, from uint64, to uint64, c redis.Conn) ([]PostData, error) {
	key := getGPubKey(gID)
	publishes, err := redis.Strings(c.Do("ZRANGEBYSCORE", key, from, to))
	if err != nil {
		return nil, err
	}

	var results []PostData
	for _, publish := range publishes {
		var oID uint64
		var pID uint64
		fmt.Sscanf(publish, "%d:%d", &oID, &pID)

		if uID != oID {
			isBlacklist, err := user.IsBlacklist(uID, oID, c)
			if err != nil {
				return nil, err
			}
			if isBlacklist {
				continue
			}
		}

		post, err := dbGetPost(oID, pID, c)
		if err != nil {
			return nil, err
		}

		// get group comments
		post.Comments, err = dbGetComments(oID, post.ID, uID, gID, 0, c)
		if err != nil {
			return nil, err
		}
		results = append(results, post)
	}

	return results, nil
}
