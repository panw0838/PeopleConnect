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

type AddContactInput struct {
	User    uint64 `json:"user"`
	Contact uint64 `json:"contact"`
	Flag    uint64 `json:"flag"`
	Name    string `json:"name"`
}

func AddContactHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var input AddContactInput
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	if input.User == input.Contact {
		fmt.Fprintf(w, "Error, invalid contact")
		return
	}

	nameLen := len(input.Name)
	if nameLen == 0 || nameLen > int(NAME_SIZE) {
		fmt.Fprintf(w, "Error, invalid contact name")
		return
	}

	if input.Flag == 0 || input.Flag&BLK_BIT != 0 {
		fmt.Fprintf(w, "Error, invalid group")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: connect db error")
		return
	}
	defer c.Close()

	flag, err := DbGetFlag(input.User, input.Contact, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	if flag != 0 {
		fmt.Fprintf(w, "Error: account already add")
		return
	}

	otherFlag, err := DbGetFlag(input.Contact, input.User, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	if otherFlag&BLK_BIT != 0 {
		fmt.Fprintf(w, "Error: account not exists")
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
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var input RemContactInput
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	err = dbRemoveContact(input.User, input.Contact)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "Success")
}
