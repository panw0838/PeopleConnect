package post

import (
	"fmt"
	"message"
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
		values, err := redis.Int64s(c.Do("SMEMBERS", contactsKey))
		if err != nil {
			return err
		}

		for _, value := range values {
			cID := uint64(value)
			canSee, err := canSeeFPost(cID, uID, post.Flag, c)
			if err != nil {
				return err
			}
			if canSee {
				fpostsKey := getFPubKey(cID)
				_, err := c.Do("ZADD", fpostsKey, post.ID, publishStr)
				if err != nil {
					return err
				}

				var msg message.Message
				msg.Type = message.NTF_NEW
				err = message.DbAddMessege(cID, msg, c)
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
		geoIDs := share.GetGeoIDs(post.X, post.Y)
		nearKey := getNearKey(geoIDs[0])
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
		success, post, err := dbGetPost(oID, pID, c)
		if err != nil {
			return nil, err
		}
		if success {
			post.Liked, err = dbGetLike(uID, oID, pID, c)
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
	}

	return results, nil
}

func dbGetNearbyPublish(uID uint64, geoID uint64, from uint64, to uint64, c redis.Conn) ([]PostData, error) {
	var results []PostData
	nearKey := getNearKey(geoID)
	publishes, err := redis.Strings(c.Do("ZRANGEBYSCORE", nearKey, from, to))
	if err != nil {
		return nil, err
	}

	for _, publish := range publishes {
		var oID uint64
		var pID uint64
		fmt.Sscanf(publish, "%d:%d", &oID, &pID)

		if uID == oID {
			continue
		}

		isStranger, err := user.IsStranger(uID, oID, c)
		if err != nil {
			return nil, err
		}
		if !isStranger {
			continue
		}

		success, post, err := dbGetPost(oID, pID, c)
		if err != nil {
			return nil, err
		}
		if success {
			post.Liked, err = dbGetLike(uID, oID, pID, c)
			if err != nil {
				return nil, err
			}
			// get strangers comments
			post.Comments, err = dbGetComments(oID, post.ID, uID, StrangerGroup, 0, c)
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

		if uID == oID {
			continue
		}

		isBlacklist, err := user.IsBlacklist(uID, oID, c)
		if err != nil {
			return nil, err
		}
		if isBlacklist {
			continue
		}

		success, post, err := dbGetPost(oID, pID, c)
		if err != nil {
			return nil, err
		}
		if success {
			post.Liked, err = dbGetLike(uID, oID, pID, c)
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
	}

	return results, nil
}
