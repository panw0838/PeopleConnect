package user

import (
	"fmt"
	"net/http"

	"github.com/garyburd/redigo/redis"
)

func RegisterHandler(w http.ResponseWriter, r *http.Request) {
	// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "ParseForm() err: %v", err)
		return
	}
	cellNumber := r.FormValue("cell")
	deviceID := r.FormValue("device")

	if len(cellNumber) == 0 {
		fmt.Fprintf(w, "Error: null cell number")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	userID, err := dbRegiste(cellNumber, deviceID, c)
	if err != nil {
		fmt.Fprintf(w, "Fail cell : %s, machine : %s\n %v",
			cellNumber, deviceID, err)
		return
	}
	fmt.Fprintf(w, "Success %x cell : %s, machine : %s",
		userID, cellNumber, deviceID)
}

func LoginHandler(w http.ResponseWriter, r *http.Request) {
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
