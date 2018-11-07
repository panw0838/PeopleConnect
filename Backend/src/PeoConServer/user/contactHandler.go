package user

import (
	"fmt"
	"net/http"
	"strconv"
)

func getContactsHandler(w http.ResponseWriter, r *http.Request) {
	var username = ""
	var password = ""
	var response = ""
	if r.Method == "POST" {
		// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
		if err := r.ParseForm(); err != nil {
			fmt.Fprintf(w, "ParseForm() err: %v", err)
			return
		}
		username = r.FormValue("user")
		password = r.FormValue("pass")
		userID, err := strconv.ParseUint(username, 16, 32)
		if err != nil {
			fmt.Fprintf(w, "Conver uid %s fail", username)
		}
		response, err = GetContacts(uint32(userID))
		if err != nil {
			fmt.Fprintf(w, "Get Contacts fail %v", err)
			return
		}
	}
	fmt.Fprintf(w, "%s:%s->%s", username, password, response)
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

		DBAddContact(uint32(userID), uint32(contactID), uint32(flag), name)
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

		DBRemoveContact(uint32(userID), uint32(contactID))
	}
	fmt.Fprintf(w, "Success")
}
