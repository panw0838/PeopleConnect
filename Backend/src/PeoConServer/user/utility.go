package user

import (
	"strconv"

	"github.com/garyburd/redigo/redis"
)

func GetUint64(reply interface{}, err error) (uint64, error) {
	str, err := redis.String(reply, err)
	if err != nil {
		return 0, err
	}
	value, err := strconv.ParseUint(str, 10, 64)
	if err != nil {
		return 0, err
	}
	return value, nil
}
