package user

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"

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

	contactID, err := dbSearchContact(input.User, input.Key)
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

func AddContactHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
		if err := r.ParseForm(); err != nil {
			fmt.Fprintf(w, "ParseForm() err: %v", err)
			return
		}
		username := r.FormValue("user")
		contact := r.FormValue("contact")
		name := r.FormValue("name")

		userID, err := strconv.ParseUint(username, 16, 32)
		if err != nil {
			fmt.Fprintf(w, "Error, invalid user %s", username)
			return
		}

		contactID, err := strconv.ParseUint(contact, 16, 32)
		if err != nil {
			fmt.Fprintf(w, "Error, invalid contact %s", username)
			return
		}

		if len(name) == 0 || len(name) > int(NAME_SIZE) {
			fmt.Fprintf(w, "Error, invalid contact name")
			return
		}

		flag, err := strconv.ParseUint(r.FormValue("flag"), 16, 32)
		if err != nil {
			fmt.Fprintf(w, "Error, invalid flag")
			return
		}

		if flag == 0 {
			fmt.Fprintf(w, "Error, invalid group")
			return
		}

		err = dbAddContact(userID, contactID, flag, name)
		if err != nil {
			fmt.Fprintf(w, "Error, %v", err)
		}
	}
	fmt.Fprintf(w, "Success")
}

func RemContactHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
		if err := r.ParseForm(); err != nil {
			fmt.Fprintf(w, "ParseForm() err: %v", err)
			return
		}
		username := r.FormValue("user")
		contact := r.FormValue("contact")

		userID, err := strconv.ParseUint(username, 16, 32)
		if err != nil {
			fmt.Fprintf(w, "Error, invalid user %s", username)
			return
		}

		contactID, err := strconv.ParseUint(contact, 16, 32)
		if err != nil {
			fmt.Fprintf(w, "Error, invalid contact %s", username)
			return
		}

		dbRemoveContact(userID, contactID)
	}
	fmt.Fprintf(w, "Success")
}
