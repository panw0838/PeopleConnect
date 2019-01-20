package setup

import (
	"share"
	"user"

	"github.com/garyburd/redigo/redis"
)

func InitNewUID() {
	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		panic(err)
	}
	defer c.Close()

	val, err := c.Do("GET", user.NewUIDKey)
	if err != nil {
		panic(err)
	}
	if val == nil {
		_, err = c.Do("SET", user.NewUIDKey, 10000000)
		if err != nil {
			panic(err)
		}
	}
}
