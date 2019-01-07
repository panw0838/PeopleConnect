package message

import (
	"encoding/json"
	"share"
	"strconv"
	"time"
	"user"

	"github.com/garyburd/redigo/redis"
)

// messages
const MSG_STR uint8 = 0x00
const MSG_PIC uint8 = 0x01
const MSG_VID uint8 = 0x02

// notifications requests
const NTF_REQ uint8 = 0x10
const NTF_ADD uint8 = 0x11
const NTF_LIK uint8 = 0x12

// notifications posts
const NTF_PST_CMT uint8 = 0x20
const NTF_PST_LIK uint8 = 0x21
const NTF_PST_NEW uint8 = 0x22

type Message struct {
	From uint64 `json:"from"`
	Type uint8  `json:"type"`
	Time uint64 `json:"time"`
	// for message
	Content string `json:"cont,omitempty"`
	// for post notify
	OID uint64 `json:"oid,omitempty"`
	PID uint64 `json:"pid,omitempty"`
	Src uint32 `json:"src,omitempty"`
}

func getMsgKey(userID uint64) string {
	return "msg:" + strconv.FormatUint(userID, 10)
}

func DbAddMessege(to uint64, msg Message, c redis.Conn) (uint64, error) {
	msg.Time = share.GetTimeID(time.Now())
	data, err := json.Marshal(msg)
	if err != nil {
		return 0, err
	}
	msgKey := getMsgKey(to)
	_, err = c.Do("ZADD", msgKey, msg.Time, data)
	if err != nil {
		return 0, err
	}
	return msg.Time, nil
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

func dbAddRequest(input RequestContactInput, c redis.Conn) uint16 {
	requestsKey := share.GetRequestsKey(input.To)
	values, err := redis.Values(c.Do("ZRANGEBYSCORE", requestsKey, input.From, input.From))
	if err != nil {
		return 1
	}
	if len(values) != 0 {
		return 1
	}

	var info RequestInfo

	info.From = input.From
	info.Name = input.Name
	info.Msg = input.Message

	data, err := json.Marshal(info)
	if err != nil {
		return 1
	}

	_, err = c.Do("ZADD", requestsKey, input.From, data)
	if err != nil {
		return 1
	}

	// add to message notification
	var msg Message
	msg.From = input.From
	msg.Type = NTF_REQ
	_, err = DbAddMessege(input.To, msg, c)
	if err != nil {
		return 1
	}

	return 0
}

func dbRemRequest(input DeclienRequestInput, c redis.Conn) uint16 {
	requestsKey := share.GetRequestsKey(input.UID)
	_, err := c.Do("ZREMRANGEBYSCORE", requestsKey, input.CID, input.CID)
	if err != nil {
		return 1
	}
	return 0
}

func dbSyncRequests(uID uint64, c redis.Conn) ([]RequestInfo, error) {
	requestsKey := share.GetRequestsKey(uID)
	var requests []RequestInfo
	values, err := redis.Values(c.Do("ZRANGE", requestsKey, 0, -1))
	for _, value := range values {
		data, err := redis.Bytes(value, err)
		if err != nil {
			return nil, err
		}

		var request RequestInfo
		err = json.Unmarshal(data, &request)
		if err != nil {
			return nil, err
		}
		// replace note name to user name
		request.Name, err = user.DbGetUserName(request.From, c)
		if err != nil {
			return nil, err
		}

		requests = append(requests, request)
	}

	return requests, nil
}
