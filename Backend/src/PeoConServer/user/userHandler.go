package user

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/garyburd/redigo/redis"
)

func RegisterHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var registryInfo RegistryInfo
	err = json.Unmarshal(body, &registryInfo)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}

	if len(registryInfo.CellNumber) == 0 {
		fmt.Fprintf(w, "Error: null cell number")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	userID, err := dbRegistry(registryInfo, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var feedback LogonFeedbackInfo
	feedback.UserID = userID

	data, err := json.Marshal(&feedback)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", data)
}

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var loginInfo LoginInfo
	err = json.Unmarshal(body, &loginInfo)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	userID, err := dbVerifyUser(loginInfo, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var feedback LogonFeedbackInfo
	feedback.UserID = userID

	data, err := json.Marshal(&feedback)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", data)
}
