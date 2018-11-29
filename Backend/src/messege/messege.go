package messege

import (
	"encoding/json"
	"fmt"
	"net/http"
	"share"
	"strconv"
	"strings"
	"time"
	"user"

	"github.com/garyburd/redigo/redis"
)

type Messege struct {
	From    uint64 `json:"from"`
	Time    string `json:"time"`
	Content string `json:"cont"`
}

func GetMessegeKey(userID uint64) string {
	return "msg:" + strconv.FormatUint(userID, 10)
}

func sendSyncRequest(address string) error {
	_, err := http.Get(address)
	if err != nil {
		return err
	}
	return nil
}

func dbAddMessege(input SendMessegeInput, c redis.Conn) error {
	var msg Messege
	msg.From = input.From
	msg.Time = time.Now().Format(time.RFC3339)
	msg.Content = input.Mess
	data, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	msgKey := GetMessegeKey(input.To)
	_, err = c.Do("RPUSH", msgKey, data)
	if err != nil {
		return err
	}
	return nil
}

func dbGetMesseges(input MessegeSyncInput, c redis.Conn) (uint32, []Messege, error) {
	messegeKey := GetMessegeKey(input.User)

	// no messege
	messSize, err := redis.Int(c.Do("LLEN", messegeKey))
	if err != nil {
		return 0, nil, err
	}
	if messSize == 0 {
		return 0, nil, nil
	}

	var newSyncID = input.Sync
	var syncedIdx int = -1
	var i int
	var messeges []Messege
	var pushNewSync = true
	for i = 0; i < messSize; i++ {
		msgData, err := redis.String(c.Do("LINDEX", messegeKey, i))
		if err != nil {
			return 0, nil, err
		}
		if strings.HasPrefix(msgData, "Sync:") {
			var syncID uint32
			fmt.Sscanf(msgData, "Sync:%d", &syncID)
			if i == (messSize - 1) {
				pushNewSync = false
			}
			if syncID <= input.Sync {
				var newMesseges []Messege
				messeges = newMesseges
				syncedIdx = i
			} else {
				newSyncID = syncID
			}
		} else {
			var messege Messege
			err := json.Unmarshal([]byte(msgData), &messege)
			if err != nil {
				return 0, nil, err
			}
			messeges = append(messeges, messege)
		}
	}

	if syncedIdx > 0 {
		_, err := c.Do("LTRIM", messegeKey, syncedIdx+1, -1)
		if err != nil {
			return 0, nil, err
		}
		messSize -= (syncedIdx + 1)
	}

	if pushNewSync {
		newSyncID += 1
		syncData := fmt.Sprintf("Sync:%d", newSyncID)
		newSize, err := redis.Int(c.Do("RPUSH", messegeKey, syncData))
		if err != nil {
			return 0, nil, err
		}

		if newSize > (messSize + 1) {
			for i = messSize; i < (newSize - 1); i++ {
				msgData, err := redis.Bytes(c.Do("LINDEX", messegeKey, i))
				if err != nil {
					return 0, nil, err
				}
				var messege Messege
				err = json.Unmarshal(msgData, &messege)
				if err != nil {
					return 0, nil, err
				}
				messeges = append(messeges, messege)
			}
		}
	}

	return newSyncID, messeges, nil
}

func dbAddRequest(input RequestContactInput, c redis.Conn) error {
	_, err := c.Do("MULTI")
	if err != nil {
		return err
	}

	requestKey := share.GetRequestKey(input.From, input.To)
	_, err = c.Do("HMSET", requestKey,
		user.FlagField, input.Flag,
		user.NameField, input.Name,
		user.MessField, input.Message)
	if err != nil {
		return err
	}

	requestsKey := share.GetRequestsKey(input.To)
	_, err = c.Do("SADD", requestsKey, input.From)
	if err != nil {
		return err
	}

	_, err = c.Do("EXEC")
	if err != nil {
		return err
	}
	return nil
}

func dbSyncRequests(uID uint64, c redis.Conn) ([]Request, error) {
	requestsKey := share.GetRequestsKey(uID)
	numRequests, err := redis.Uint64(c.Do("SCARD", requestsKey))
	if err != nil {
		return nil, err
	}
	if numRequests == 0 {
		return nil, nil
	}

	var requests []Request
	rawDatas, err := redis.Values(c.Do("SMEMBERS", requestsKey))
	for _, rawData := range rawDatas {
		var request Request
		from, err := share.GetUint64(rawData, err)
		if err != nil {
			return nil, err
		}
		request.From = from

		fromAccountKey := user.GetAccountKey(from)
		name, err := user.DbGetUserInfoField(fromAccountKey, user.NameField, c)
		if err != nil {
			return nil, err
		}
		request.Name = name

		requestKey := share.GetRequestKey(from, uID)
		values, err := redis.Values(c.Do("HMGET", requestKey, user.MessField))
		messege, err := redis.String(values[0], err)
		if err != nil {
			return nil, err
		}
		request.Mess = messege

		requests = append(requests, request)
	}

	return requests, nil
}
