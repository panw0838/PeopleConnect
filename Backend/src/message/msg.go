package message

import (
	"encoding/json"
	"share"
	"strconv"
	"time"
	"user"

	"github.com/garyburd/redigo/redis"
)

type Message struct {
	From    uint64 `json:"from"`
	Time    uint64 `json:"time"`
	Content string `json:"cont"`
}

func getMsgKey(userID uint64) string {
	return "msg:" + strconv.FormatUint(userID, 10)
}

func dbAddMessege(input SendMsgInput, c redis.Conn) error {
	var msg Message
	msg.From = input.From
	msg.Time = share.GetTimeID(time.Now())
	msg.Content = input.Msg
	data, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	msgKey := getMsgKey(input.To)
	_, err = c.Do("ZADD", msgKey, msg.Time, data)
	if err != nil {
		return err
	}
	return nil
}

func dbGetMessages(input MessegeSyncInput, c redis.Conn) (uint64, []Message, error) {
	msgKey := getMsgKey(input.User)

	// delete old msg
	_, err := c.Do("ZREMRANGEBYSCORE", msgKey, 0, input.Sync)
	if err != nil {
		return 0, nil, err
	}

	// get new msg
	values, err := redis.Values(c.Do("ZRANGEBYSCORE", msgKey, input.Sync+1, share.MAX_TIME))
	if err != nil {
		return 0, nil, err
	}

	var messages []Message
	var newSync = input.Sync

	for _, value := range values {
		data, err := redis.Bytes(value, err)
		if err != nil {
			return 0, nil, err
		}
		var msg Message
		err = json.Unmarshal(data, &msg)
		if err != nil {
			return 0, nil, err
		}

		newSync = msg.Time
		messages = append(messages, msg)
	}

	return newSync, messages, nil
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
