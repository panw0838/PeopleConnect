package share

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const ContactDB = "127.0.0.1:6379"

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

func ReadInput(r *http.Request, v interface{}) error {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return err
	}

	err = json.Unmarshal(body, v)
	if err != nil {
		return err
	}

	return nil
}

func GetRequestsKey(user uint64) string {
	return "requests:" + strconv.FormatUint(user, 10)
}

func GetRequestKey(user1 uint64, user2 uint64) string {
	return "request:" +
		strconv.FormatUint(user1, 10) + ":" +
		strconv.FormatUint(user2, 10)
}
