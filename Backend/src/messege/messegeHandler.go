package messege

import (
	"encoding/json"
	"fmt"
	"net/http"
	"share"
	"user"

	"github.com/garyburd/redigo/redis"
)

/*
type SendMessegeInput struct {
	From uint64 `json:"from"`
	To   uint64 `json:"to"`
	Mess string `json:"mess"`
}

type SendMessegeReturn struct {
	IPAddress string `json:"ip"`
}


func SendMessegeHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var input SendMessegeInput
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	relation, err := user.GetRelation(input.From, input.To, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	if !user.IsFriend(relation) {
		fmt.Fprintf(w, "Error: not friend %v", relation)
		return
	}

	// TODO, notify user2 to receive messege
	cashed, userCash := share.GetAccountCash(input.To)
	if cashed {
		ipStr := share.GetIPString(userCash.Ip)
		sendSyncRequest(ipStr + ":8181/sync")
	}

	err = dbAppendMessege(input, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var response SendMessegeReturn
	inCash, userCash := share.GetAccountCash(input.To)
	if inCash {
		response.IPAddress = share.GetIPString(userCash.Ip)
	} else {
		response.IPAddress = ""
	}
	data, err := json.Marshal(&response)
	if err != nil {
		fmt.Fprintf(w, "Error: json output error %s", data)
		return
	}

	fmt.Fprintf(w, "%s", data)
}
*/

type MessegeSyncInput struct {
	User uint64 `json:"user"`
	Sync uint32 `json:"sync"`
	//Last uint32 `json:"last"`
}

type MessegeSyncReturn struct {
	Sync     uint32    `json:"sync"`
	Messeges []Messege `json:"mess"`
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
	newSyncID, messeges, err := dbGetMesseges(input, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	output.Messeges = messeges
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
