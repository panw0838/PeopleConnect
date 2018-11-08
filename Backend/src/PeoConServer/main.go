package main

import (
	"PeoConServer/user"
	"fmt"
	"net/http"
)

func syncHandler(w http.ResponseWriter, r *http.Request) {
}

func getMessagesHandler(w http.ResponseWriter, r *http.Request) {
}

func getContactsHandler(w http.ResponseWriter, r *http.Request) {
}

func main() {
	//http.HandleFunc("/register", registerHandler)
	//http.HandleFunc("/login", loginHandler)
	//log.Fatal(http.ListenAndServe(":8080", nil))
	//if e := http.ListenAndServeTLS(":8080", "server.crt", "server.key", nil); e != nil {
	//	log.Fatal("ListenAndServe: ", e)
	//}
	ttt := user.GetContacts(0)
	fmt.Printf("%s\n", ttt)
}
