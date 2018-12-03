package user

import (
	"share"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

func GetPositionKey() string {
	return "position"
}

func dbGetStrangers(uID uint64, posID uint64, c redis.Conn) ([]uint64, error) {
	posKey := GetPositionKey()
	var step uint64 = 0x3
	values, err := redis.Values(c.Do("ZRANGEBYSCORE", posKey, posID-step, posID+step))
	if err != nil {
		return nil, err
	}
	var results []uint64
	for _, value := range values {
		cID, err := share.GetUint64(value, err)
		if err != nil {
			return nil, err
		}
		if uID != cID {
			isStranger, err := IsStranger(uID, cID, c)
			if err != nil {
				return nil, err
			}
			if isStranger {
				results = append(results, cID)
			}
		}
	}
	return results, nil
}

func getUnionKey(uID uint64) string {
	return "union:" + strconv.FormatUint(uID, 10)
}

func dbUpdatePoContacts(uID uint64, c redis.Conn) error {
	uKey := GetContactsKey(uID)
	values, err := redis.Strings(c.Do("SMEMBERS", uKey))
	if err != nil {
		return err
	}

	uinonKey := getUnionKey(uID)
	for _, value := range values {
		cID, err := share.GetUint64(value, err)
		if err != nil {
			return err
		}
		cKey := GetContactsKey(cID)
		contacts, err := redis.Strings(c.Do("SDIFF", cKey, uKey))
		if err != nil {
			return err
		}
		for _, contact := range contacts {
			_, err = c.Do("ZINCRBY", uinonKey, 1, contact)
			if err != nil {
				return err
			}
		}
	}

	_, err = c.Do("ZREM", uinonKey, uID)
	if err != nil {
		return err
	}

	_, err = c.Do("ZREMRANGEBYSCORE", uinonKey, 0, 1)
	if err != nil {
		return err
	}

	return nil
}
