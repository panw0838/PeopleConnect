package message

import (
	"encoding/json"
	"fmt"
	"net/http"
	"share"
	"user"

	"github.com/garyburd/redigo/redis"
)

type SendMsgInput struct {
	From uint64 `json:"from"`
	To   uint64 `json:"to"`
	Msg  string `json:"msg"`
}

func SendMessegeHandler(w http.ResponseWriter, r *http.Request) {
	var input SendMsgInput
	err := share.ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	friend, err := user.IsFriend(input.From, input.To, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	if !friend {
		fmt.Fprintf(w, "Error: not friend")
		return
	}

	err = dbAddMessege(input, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "Success")
}

type MessegeSyncInput struct {
	User uint64 `json:"user"`
	Sync uint64 `json:"sync"`
	//Last uint32 `json:"last"`
}

type MessegeSyncReturn struct {
	Sync     uint64    `json:"sync"`
	Messages []Message `json:"mess"`
}

func SyncMessegeHandler(w http.ResponseWriter, r *http.Request) {
	var input MessegeSyncInput
	err := share.ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: read input")
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	var output MessegeSyncReturn
	newSyncID, messages, err := dbGetMessages(input, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	output.Messages = messages
	output.Sync = newSyncID

	data, err := json.Marshal(&output)
	if err != nil {
		fmt.Fprintf(w, "Error: json write error")
		return
	}

	fmt.Fprintf(w, "%s", data)
}

type RequestContactInput struct {
	From    uint64 `json:"from"`
	To      uint64 `json:"to"`
	Flag    uint64 `json:"flag"`
	Name    string `json:"name"`
	Message string `json:"mess"`
}

func RequestContactHandler(w http.ResponseWriter, r *http.Request) {
	var input RequestContactInput
	err := share.ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: read input")
		return
	}

	err = user.AddContactPreCheck(input.From, input.To, input.Flag, input.Name)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	requestKey := share.GetRequestKey(input.From, input.To)
	exists, err := redis.Int64(c.Do("EXISTS", requestKey))
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	if exists == 1 {
		fmt.Fprintf(w, "Error: request exist")
		return
	}

	err = dbAddRequest(input, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "Success")
}

type SyncRequestsInput struct {
	User uint64 `json:"user"`
}

type Request struct {
	From uint64 `json:"from"`
	Name string `json:"name"`
	Mess string `json:"mess"`
}

type SyncRequestsReturn struct {
	Requests []Request `json:"requests"`
}

func SyncRequestsHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncRequestsInput
	err := share.ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: read input")
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	requests, err := dbSyncRequests(input.User, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var response SyncRequestsReturn
	response.Requests = requests
	data, err := json.Marshal(&response)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", data)
		return
	}

	fmt.Fprintf(w, "%s", data)
}
