package user

import (
	"encoding/json"
	"fmt"
	"net/http"
	"share"

	"github.com/garyburd/redigo/redis"
)

type AccountInfo struct {
	UserID uint64 `json:"user"`
}

type RegistryInfo struct {
	CellNumber string `json:"cell"`
	CellCode   string `json:"code,omitempty"`
	Password   string `json:"pass,omitempty"`
	Device     string `json:"device"`
	IPAddress  string
}

func RegisterHandler(w http.ResponseWriter, r *http.Request) {
	var registryInfo RegistryInfo
	err := share.ReadInput(r, &registryInfo)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}

	registryInfo.IPAddress = r.RemoteAddr

	if len(registryInfo.CellNumber) == 0 {
		fmt.Fprintf(w, "Error: null cell number")
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
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

	var response AccountInfo
	response.UserID = userID
	share.SetAccountCash(userID, registryInfo.IPAddress, 0)

	data, err := json.Marshal(&response)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", data)
}

type LoginInfo struct {
	CellNumber string `json:"cell"`
	CellCode   string `json:"code,omitempty"`
	Password   string `json:"pass,omitempty"`
	Device     string `json:"device"`
	IPAddress  string
}

type LoginResponse struct {
	UserID uint64 `json:"user"`
}

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	var loginInfo LoginInfo
	err := share.ReadInput(r, &loginInfo)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}
	loginInfo.IPAddress = r.RemoteAddr

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	userID, err := dbLogon(loginInfo, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var feedback LoginResponse
	feedback.UserID = userID
	share.SetAccountCash(userID, loginInfo.IPAddress, 0)

	data, err := json.Marshal(&feedback)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", data)
}
