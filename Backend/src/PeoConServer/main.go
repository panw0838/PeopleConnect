package main

import (
	"PeoConServer/user"
	"fmt"
	"log"
	"net/http"
)

const crtPath = "C:/Users/panwang/PeopleConnect/Backend/src/PeoConServer/server.crt"
const keyPath = "C:/Users/panwang/PeopleConnect/Backend/src/PeoConServer/server.key"

func syncHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hi, This is an example of https service in golang!")
}

func getMessagesHandler(w http.ResponseWriter, r *http.Request) {
}

func getContactsHandler(w http.ResponseWriter, r *http.Request) {
}

func main() {
	http.HandleFunc("/sync", syncHandler)
	http.HandleFunc("/login", user.LoginHandler)
	http.HandleFunc("/register", user.RegisterHandler)
	e := http.ListenAndServeTLS(":8080", crtPath, keyPath, nil)
	if e != nil {
		log.Fatal("ListenAndServe: ", e)
	}
	//log.Fatal(http.ListenAndServe(":8080", nil))
	//ttt := user.GetContacts(0)
	//fmt.Printf("%s\n", ttt)
}
