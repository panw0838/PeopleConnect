package user

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

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

	var fullInfo FullContactInfo

	contacts, err := dbGetContacts(account.UserID, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	fullInfo.Contacts = contacts

	tags, err := dbGetTags(account.UserID, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	fullInfo.Tags = tags

	data, err := json.Marshal(&contacts)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", data)
}

func addContactHandler(w http.ResponseWriter, r *http.Request) {
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

		DBAddContact(userID, contactID, flag, name)
	}
	fmt.Fprintf(w, "Success")
}

func removeContactHandler(w http.ResponseWriter, r *http.Request) {
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

		DBRemoveContact(userID, contactID)
	}
	fmt.Fprintf(w, "Success")
}
