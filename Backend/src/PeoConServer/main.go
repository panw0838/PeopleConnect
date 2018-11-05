package main

import (
	"fmt"
	"log"
	"net/http"
)

func registerHandler(w http.ResponseWriter, r *http.Request) {
	var cellNumber = ""
	var machineID = ""
	if r.Method == "POST" {
		// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
		if err := r.ParseForm(); err != nil {
			fmt.Fprintf(w, "ParseForm() err: %v", err)
			return
		}
		cellNumber = r.FormValue("cell")
		machineID = r.FormValue("maid")
	}
	fmt.Fprintf(w, "cell : %s, machine : %s", cellNumber, machineID)
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	var username = ""
	var password = ""
	if r.Method == "POST" {
		// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
		if err := r.ParseForm(); err != nil {
			fmt.Fprintf(w, "ParseForm() err: %v", err)
			return
		}
		username = r.FormValue("user")
		password = r.FormValue("pass")
	}
	fmt.Fprintf(w, "%s:%s", username, password)
}

func syncHandler(w http.ResponseWriter, r *http.Request) {
}

func getMessagesHandler(w http.ResponseWriter, r *http.Request) {
}

func getContactsHandler(w http.ResponseWriter, r *http.Request) {
}

func main() {
	http.HandleFunc("/register", registerHandler)
	http.HandleFunc("/login", loginHandler)
	log.Fatal(http.ListenAndServe(":8080", nil))
	//if e := http.ListenAndServeTLS(":8080", "server.crt", "server.key", nil); e != nil {
	//	log.Fatal("ListenAndServe: ", e)
	//}
}
