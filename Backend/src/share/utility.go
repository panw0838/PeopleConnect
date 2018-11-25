package share

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const ONE_64 uint64 = 0x1
const ZERO_64 uint64 = 0x0

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

func GetIndex(str string, c byte, n int) int {
	var left = n
	var i = 0
	for {
		if left == 0 {
			break
		}
		if str[i] == c {
			left--
		}
		i++
	}
	return i - 1
}

func GetRequestsKey(user uint64) string {
	return "requests:" + strconv.FormatUint(user, 10)
}

func GetRequestKey(user1 uint64, user2 uint64) string {
	return "request:" +
		strconv.FormatUint(user1, 10) + ":" +
		strconv.FormatUint(user2, 10)
}
