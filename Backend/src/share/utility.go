package share

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"strconv"
	"time"

	"github.com/garyburd/redigo/redis"
)

const ONE_64 uint64 = 0x1
const ZERO_64 uint64 = 0x0
const MAX_TIME uint64 = 0xffffffffffffffff

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

func GetTimeID(t time.Time) uint64 {
	var startTime = time.Date(2018, 1, 1, 0, 0, 0, 0, time.Local)
	duration := t.Sub(startTime)
	return uint64(duration / 1000 / 1000 / 1000)
}

func GetGeoID(x float64, y float64) uint64 {
	var resultX uint64 = 0
	var _x float64 = x + 90
	var midX float64 = 90.0
	steps := 20
	for i := 0; i < steps; i++ {
		if _x > midX {
			resultX |= 0x1
			_x -= midX
		}
		midX /= 2
		if i < (steps - 1) {
			resultX <<= 2
		}
	}
	var resultY uint64 = 0
	var _y float64 = y + 180
	var midY float64 = 180.0
	for i := 0; i < steps; i++ {
		if _y > midY {
			resultY |= 0x2
			_y -= midY
		}
		midY /= 2
		if i < (steps - 1) {
			resultY <<= 2
		}
	}
	return (resultX | resultY)
}

func GetRequestsKey(user uint64) string {
	return "requests:" + strconv.FormatUint(user, 10)
}

func GetRequestKey(user1 uint64, user2 uint64) string {
	return "request:" +
		strconv.FormatUint(user1, 10) + ":" +
		strconv.FormatUint(user2, 10)
}
