package user

import (
	"fmt"
	"net/http"
)

func registerHandler(w http.ResponseWriter, r *http.Request) {
	// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "ParseForm() err: %v", err)
		return
	}
	cellNumber := r.FormValue("cell")
	deviceID := r.FormValue("device")
	fmt.Fprintf(w, "cell : %s, machine : %s", cellNumber, deviceID)
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	var username = ""
	var password = ""
	// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "ParseForm() err: %v", err)
		return
	}
	username = r.FormValue("user")
	password = r.FormValue("pass")
	fmt.Fprintf(w, "%s:%s", username, password)
}
