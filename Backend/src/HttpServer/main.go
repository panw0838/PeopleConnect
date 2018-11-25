package main

import (
	"fmt"
	"log"
	"messege"
	"net/http"
	"user"
)

const crtPath = "C:/Users/panwang/PeopleConnect/Backend/src/server.crt"
const keyPath = "C:/Users/panwang/PeopleConnect/Backend/src/server.key"

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
	sss := r.Header.Get("X-Forwarded-For")
	fmt.Fprintf(w, "%s %s", r.RemoteAddr, sss)
}

func getMessagesHandler(w http.ResponseWriter, r *http.Request) {
}

func getContactsHandler(w http.ResponseWriter, r *http.Request) {
}

func main() {
	http.HandleFunc("/sync", syncHandler)

	http.HandleFunc("/login", user.LoginHandler)
	http.HandleFunc("/registry", user.RegisterHandler)

	http.HandleFunc("/addtag", user.AddTagHandler)
	http.HandleFunc("/remtag", user.RemTagHandler)

	http.HandleFunc("/contacts", user.GetContactsHandler)
	http.HandleFunc("/searchcontact", user.SearchContactHandler)
	http.HandleFunc("/addcontact", user.AddContactHandler)
	http.HandleFunc("/remcontact", user.RemContactHandler)
	http.HandleFunc("/updatetagmember", user.UpdateTagMemberHandler)

	http.HandleFunc("/syncmessege", messege.SyncMessegeHandler)
	http.HandleFunc("/requestcontact", messege.RequestContactHandler)
	http.HandleFunc("/syncrequests", messege.SyncRequestsHandler)
	//http.HandleFunc("/sendmessege", messege.SendMessegeHandler)

	e := http.ListenAndServeTLS(":8080", crtPath, keyPath, nil)
	if e != nil {
		log.Fatal("ListenAndServe: ", e)
	}
}
