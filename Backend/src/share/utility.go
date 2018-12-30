package share

import (
	"encoding/binary"
	"encoding/json"
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
	var startTime = time.Date(2001, 1, 1, 0, 0, 0, 0, time.UTC)
	duration := t.Sub(startTime)
	return uint64(duration / 1000 / 1000 / 1000)
}

func GetGeoID(x float64, y float64) uint64 {
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
