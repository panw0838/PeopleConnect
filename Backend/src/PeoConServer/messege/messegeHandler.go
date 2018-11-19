package messege

import (
	"PeoConServer/user"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/garyburd/redigo/redis"
)

type SendMessegeInput struct {
	From uint64 `json:"from"`
	To   uint64 `json:"to"`
	Mess string `json:"mess"`
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

	c, err := redis.Dial("tcp", user.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	relation, err := GetRelation(input.From, input.To, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	if !IsFriend(relation) {
		fmt.Fprintf(w, "Error: not friend %v", relation)
		return
	}

	err = dbAppendMessege(input, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	// TODO, notify user2 to receive messege
}

type MessegeSyncInput struct {
	User uint64 `json:"user"`
}

type MessegeSyncReturn struct {
	Messeges []Messege `json:"mess"`
}

func SyncMessegeHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var input MessegeSyncInput
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	c, err := redis.Dial("tcp", user.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	var output MessegeSyncReturn
	messeges, err := dbGetMesseges(input.User, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	output.Messeges = messeges

	data, err := json.Marshal(&output)
	if err != nil {
		fmt.Fprintf(w, "Error: json write error")
		return
	}

	fmt.Fprintf(w, "%s", data)
}
