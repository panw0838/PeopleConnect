package user

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/garyburd/redigo/redis"
)

type GetContactsReturn struct {
	Tags     []TagInfo     `json:"tags"`
	Contacts []ContactInfo `json:"contacts"`
}

func GetContactsHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var account AccountInfo
	err = json.Unmarshal(body, &account)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: connect db error")
		return
	}
	defer c.Close()

	var response GetContactsReturn

	contacts, err := dbGetContacts(account.UserID, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	response.Contacts = contacts

	tags, err := dbGetTags(account.UserID, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	response.Tags = tags

	data, err := json.Marshal(&response)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", data)
}

type SearchContactInput struct {
	User uint64 `json:"user"`
	Key  string `json:"key"`
}

type SearchContactReturn struct {
	User uint64 `json:"user"`
	Name string `json:"name"`
}

func SearchContactHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var input SearchContactInput
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: connect db error")
		return
	}
	defer c.Close()

	contactID, err := dbSearchContact(input.User, input.Key, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	accountKey := getAccountKey(contactID)
	name, err := dbGetUserInfoField(accountKey, NameField, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var response SearchContactReturn
	response.User = contactID
	response.Name = name

	data, err := json.Marshal(&response)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
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
	err := ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: read input")
		return
	}

	err = addContactPreCheck(input.From, input.To, input.Flag, input.Name)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	requestKey := GetRequestKey(input.From, input.To)
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
	err := ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: read input")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
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

type AddContactInput struct {
	User    uint64 `json:"user"`
	Contact uint64 `json:"contact"`
	Flag    uint64 `json:"flag"`
	Name    string `json:"name"`
}

func AddContactHandler(w http.ResponseWriter, r *http.Request) {
	var input AddContactInput
	err := ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}

	err = addContactPreCheck(input.User, input.Contact, input.Flag, input.Name)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: connect db error")
		return
	}
	defer c.Close()

	requestKey := GetRequestKey(input.Contact, input.User)
	exists, err := redis.Int64(c.Do("EXISTS", requestKey))
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	if exists == 0 {
		fmt.Fprintf(w, "Error: request not exist")
		return
	}

	err = dbAddContact(input.User, input.Contact, input.Flag, input.Name, c)
	if err != nil {
		fmt.Fprintf(w, "Error, %v", err)
	}

	fmt.Fprintf(w, "Success")
}

type RemContactInput struct {
	User    uint64 `json:"user"`
	Contact uint64 `json:"contact"`
}

func RemContactHandler(w http.ResponseWriter, r *http.Request) {
	var input RemContactInput
	err := ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}

	err = dbRemoveContact(input.User, input.Contact)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "Success")
}
