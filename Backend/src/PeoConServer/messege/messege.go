package messege

import (
	"fmt"
	"strconv"
	"time"

	"github.com/garyburd/redigo/redis"
)

type MessegeTime struct {
	year   uint16
	month  uint8
	day    uint8
	hour   uint8
	minute uint8
}

type Messege struct {
	From    uint64 `json:"from"`
	Time    string `json:"time"`
	Content string `json:"cont"`
}

func GetMessegeKey(userID uint64) string {
	return "mess:" + strconv.FormatUint(userID, 10)
}

func getMessegeInfo(messegeData string) (uint64, string, string) {
	var to uint64 = 0
	var time string
	var messege string
	fmt.Sscanf(messegeData, "%d:%s:%s", &to, &time, &messege)
	return to, time, messege
}

func getMessegeData(from uint64, messege string) string {
	now := time.Now()
	year, month, day := now.Date()
	hour, minute, _ := now.Clock()
	messegeData := fmt.Sprintf("%d:%d-%d-%d-%d-%d:%s",
		from, year, month, day, hour, minute, messege)
	return messegeData
}

func dbAppendMessege(messege SendMessegeInput, c redis.Conn) error {
	messegeData := getMessegeData(messege.From, messege.Mess)
	messegeKey := GetMessegeKey(messege.To)
	_, err := c.Do("RPUSH", messegeKey, messegeData)
	if err != nil {
		return err
	}
	return nil
}

func dbGetMesseges(user uint64, c redis.Conn) ([]Messege, error) {
	messegeKey := GetMessegeKey(user)
	numMesseges, err := redis.Uint64(c.Do("LLEN", messegeKey))
	if err != nil {
		return nil, err
	}

	rawDatas, err := redis.Strings(c.Do("LRANGE", messegeKey, 0, numMesseges))
	if err != nil {
		return nil, err
	}

	var messeges []Messege
	for _, rawData := range rawDatas {
		_from, _time, _messege := getMessegeInfo(rawData)
		var messege Messege
		messege.From = _from
		messege.Time = _time
		messege.Content = _messege
		messeges = append(messeges, messege)
	}

	return messeges, nil
}
