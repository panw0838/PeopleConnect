package main

import (
	"PeoConServer/messege"
	"PeoConServer/user"
	"fmt"
	"log"
	"net/http"
)

const crtPath = "C:/Users/panwang/PeopleConnect/Backend/src/PeoConServer/server.crt"
const keyPath = "C:/Users/panwang/PeopleConnect/Backend/src/PeoConServer/server.key"

type SyncInput struct {
	Mess uint32 `json:"messID"`
	Post uint32 `json:"postID"`
}

type SyncReturn struct {
	From uint64 `json:"from"`
	To   uint64 `json:"to"`
	Mess string `json:"mess"`
}

func syncHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hi, This is an example of https service in golang!")
}

func getMessagesHandler(w http.ResponseWriter, r *http.Request) {
}

func getContactsHandler(w http.ResponseWriter, r *http.Request) {
}

func main() {
	http.HandleFunc("/login", user.LoginHandler)
	http.HandleFunc("/registry", user.RegisterHandler)

	http.HandleFunc("/addtag", user.AddTagHandler)
	http.HandleFunc("/remtag", user.RemTagHandler)

	http.HandleFunc("/contacts", user.GetContactsHandler)
	http.HandleFunc("/searchcontact", user.SearchContactHandler)
	http.HandleFunc("/requestcontact", user.RequestContactHandler)
	http.HandleFunc("/syncrequests", user.SyncRequestsHandler)
	http.HandleFunc("/addcontact", user.AddContactHandler)
	http.HandleFunc("/remcontact", user.RemContactHandler)
	http.HandleFunc("/updatetagmember", user.UpdateTagMemberHandler)

	http.HandleFunc("/syncmessege", messege.SyncMessegeHandler)
	http.HandleFunc("/sendmessege", messege.SendMessegeHandler)

	e := http.ListenAndServeTLS(":8080", crtPath, keyPath, nil)
	if e != nil {
		log.Fatal("ListenAndServe: ", e)
	}
}
