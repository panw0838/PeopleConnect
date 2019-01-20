package share

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"
	"time"

	"github.com/garyburd/redigo/redis"
)

const ONE_64 uint64 = 0x1
const ZERO_64 uint64 = 0x0
const MAX_U64 uint64 = 0x7fffffffffffffff
const MAX_TIME uint64 = MAX_U64

const ContactDB = "127.0.0.1:6379"

const MaxUploadSize = 20 * 1024 * 1024

type TimeID struct {
	Time uint64 `json:"id"`
}

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

func GetInt64(reply interface{}, err error) (int64, error) {
	str, err := redis.String(reply, err)
	if err != nil {
		return 0, err
	}
	value, err := strconv.ParseInt(str, 10, 64)
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
	var startTime = time.Date(2001, 1, 1, 0, 0, 0, 0, time.UTC)
	duration := t.Sub(startTime)
	return uint64(duration / 1000 / 1000 / 1000)
}

func expandU32ToU64(value uint64) uint64 {
	var result uint64 = 0

	var i int
	var v32 = value
	for i = 0; i < 32; i++ {
		if (v32 & 0x80000000) != 0 {
			result |= 0x1
		}
		if i != 31 {
			result <<= 2
		}
		v32 <<= 1
	}

	return result
}

func GetGeoIDs(x float64, y float64) []uint64 {
	var resultX uint64 = 0
	var _x float64 = x + 90
	var midX float64 = 90.0
	steps := 17
	for i := 0; i < steps; i++ {
		if _x > midX {
			resultX |= 0x1
			_x -= midX
		}
		midX /= 2
		if i < (steps - 1) {
			resultX <<= 1
		}
	}
	var resultY uint64 = 0
	var _y float64 = y + 180
	var midY float64 = 180.0
	for i := 0; i < steps; i++ {
		if _y > midY {
			resultY |= 0x1
			_y -= midY
		}
		midY /= 2
		if i < (steps - 1) {
			resultY <<= 1
		}
	}

	var ids []uint64

	x0 := expandU32ToU64(resultX)
	y0 := (expandU32ToU64(resultY) << 1)
	x1 := expandU32ToU64(resultX + 1)
	y1 := (expandU32ToU64(resultY+1) << 1)
	x_1 := expandU32ToU64(resultX - 1)
	y_1 := (expandU32ToU64(resultY-1) << 1)

	ids = append(ids, x0|y0)
	ids = append(ids, x_1|y0)
	ids = append(ids, x0|y_1)
	ids = append(ids, x1|y0)
	ids = append(ids, x0|y1)
	ids = append(ids, x_1|y_1)
	ids = append(ids, x1|y_1)
	ids = append(ids, x1|y1)
	ids = append(ids, x_1|y1)

	return ids
}

func GetGeoNearby() {

}

func WriteU16(w http.ResponseWriter, value uint16) {
	var bufU16 = make([]byte, 2)
	binary.LittleEndian.PutUint16(bufU16, value)
	w.Write(bufU16)
}

func WriteU32(w http.ResponseWriter, value uint32) {
	var bufU32 = make([]byte, 4)
	binary.LittleEndian.PutUint32(bufU32, value)
	w.Write(bufU32)
}

func WriteError(w http.ResponseWriter, err uint16) {
	WriteU16(w, err)
}

func WriteErrorCode(w http.ResponseWriter, err error) {
	if err != nil {
		fmt.Println(err)
		WriteError(w, 1)
	} else {
		WriteError(w, 0)
	}
}

func GetChannel(group string, c redis.Conn) (uint32, error) {
	unvKey := GetUnviKey()
	val, err := c.Do("ZSCORE", unvKey, group)
	if err != nil {
		return 0, err
	}
	if val == nil {
		return 0, fmt.Errorf("No group %s", group)
	}
	channel, err := GetInt64(val, err)
	return uint32(channel), err
}
