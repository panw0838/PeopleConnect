package user

import (
	"share"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

func GetNearKey() string {
	return "near"
}

type NearUser struct {
	UID  uint64  `json:"user"`
	Name string  `json:"name"`
	X    float64 `json:"x"`
	Y    float64 `json:"y"`
}

func dbGetNearbyUsers(input GetNearUsersInput, c redis.Conn) ([]NearUser, error) {
	geoID := share.GetGeoID(input.X, input.Y)
	nearKey := GetNearKey()

	// update user geo info
	err := dbSetUserPosition(input.UID, input.X, input.Y, c)
	if err != nil {
		return nil, err
	}

	// add user to near table
	_, err = c.Do("ZADD", nearKey, geoID, input.UID)
	if err != nil {
		return nil, err
	}

	var step uint64 = 0x3
	values, err := redis.Values(c.Do("ZRANGEBYSCORE", nearKey, geoID-step, geoID+step))
	if err != nil {
		return nil, err
	}
	var results []NearUser
	for _, value := range values {
		cID, err := share.GetUint64(value, err)
		if err != nil {
			return nil, err
		}
		if input.UID != cID {
			isStranger, err := IsStranger(input.UID, cID, c)
			if err != nil {
				return nil, err
			}
			if isStranger {
				var user NearUser
				user.UID = cID
				user.Name, err = DbGetUserName(cID, c)
				if err != nil {
					return nil, err
				}
				user.X, user.Y, err = dbGetUserPosition(cID, c)
				if err != nil {
					return nil, err
				}
				results = append(results, user)
			}
		}
	}
	return results, nil
}

func getUnionKey(uID uint64) string {
	return "union:" + strconv.FormatUint(uID, 10)
}

type PossibleContact struct {
	UID  uint64 `json:"user"`
	Name string `json:"name"`
	Conn uint32 `json:"conn"`
}

func dbGetPossibleContacts(uID uint64, c redis.Conn) ([]PossibleContact, error) {
	uinonKey := getUnionKey(uID)
	{
		uKey := GetContactsKey(uID)
		values, err := redis.Strings(c.Do("SMEMBERS", uKey))
		if err != nil {
			return nil, err
		}

		for _, value := range values {
			cID, err := share.GetUint64(value, err)
			if err != nil {
				return nil, err
			}
			cKey := GetContactsKey(cID)
			contacts, err := redis.Strings(c.Do("SDIFF", cKey, uKey))
			if err != nil {
				return nil, err
			}
			for _, contact := range contacts {
				_, err = c.Do("ZINCRBY", uinonKey, 1, contact)
				if err != nil {
					return nil, err
				}
			}
		}

		_, err = c.Do("ZREM", uinonKey, uID)
		if err != nil {
			return nil, err
		}

		// if only one share contacts, removed
		_, err = c.Do("ZREMRANGEBYSCORE", uinonKey, 0, 1)
		if err != nil {
			return nil, err
		}
	}

	numUsers, err := redis.Int(c.Do("ZCARD", uinonKey))
	if err != nil {
		return nil, err
	}

	if numUsers == 0 {
		return nil, nil
	}

	var result []PossibleContact
	values, err := redis.Values(c.Do("ZRANGE", uinonKey, 0, share.MAX_TIME, "WITHSCORES"))
	if err != nil {
		return nil, err
	}

	var isScore = false
	var contact PossibleContact
	for _, value := range values {
		if isScore {
			num, err := redis.Uint64(value, err)
			if err != nil {
				return nil, err
			}
			contact.Conn = uint32(num)
			result = append(result, contact)
		} else {
			cID, err := redis.Uint64(value, err)
			if err != nil {
				return nil, err
			}
			contact.UID = cID
			name, err := DbGetUserName(cID, c)
			if err != nil {
				return nil, err
			}
			contact.Name = name
		}
		isScore = !isScore
	}

	return result, nil
}
