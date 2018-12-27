package message

import (
	"net/http"
	"share"
	"user"

	"github.com/garyburd/redigo/redis"
)

type AddContactInput struct {
	User    uint64 `json:"user"`
	Contact uint64 `json:"contact"`
	Name    string `json:"name"`
}

func AddContactHandler(w http.ResponseWriter, r *http.Request) {
	var input AddContactInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	if input.User == input.Contact {
		share.WriteError(w, 1)
		return
	}

	nameLen := len(input.Name)
	if nameLen == 0 || nameLen > int(user.NAME_SIZE) {
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	err = dbAddContact(input.User, input.Contact, input.Name, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
}

type RemContactInput struct {
	User    uint64 `json:"user"`
	Contact uint64 `json:"contact"`
}

func RemContactHandler(w http.ResponseWriter, r *http.Request) {
	var input RemContactInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	err = dbRemoveContact(input.User, input.Contact)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
}
