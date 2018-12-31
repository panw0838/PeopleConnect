package user

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"share"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

type GetContactsReturn struct {
	Contacts []ContactInfo `json:"contacts"`
}

func GetContactsHandler(w http.ResponseWriter, r *http.Request) {
	var account AccountInfo
	err := share.ReadInput(r, &account)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	var response GetContactsReturn

	contacts, err := dbGetContacts(account.UserID, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	response.Contacts = contacts

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

type GetPostsUsersInput struct {
	UID  uint64   `json:"user"`
	CIDs []uint64 `json:"cids"`
}

type PostUser struct {
	UID  uint64 `json:"user"`
	Name string `json:"name"`
}

type GetUsersReturn struct {
	Users []PostUser `json:"users"`
}

func GetUsersHandler(w http.ResponseWriter, r *http.Request) {
	var input GetPostsUsersInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	var response GetUsersReturn

	for _, cID := range input.CIDs {
		var user PostUser

		name, err := DbGetUserName(cID, c)
		if err != nil {
			share.WriteError(w, 1)
			return
		}

		user.UID = cID
		user.Name = name

		response.Users = append(response.Users, user)
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

type GetNearUsersInput struct {
	UID uint64  `json:"user"`
	X   float64 `json:"x"`
	Y   float64 `json:"y"`
}

type GetNearUsersReturn struct {
	Users []NearUser `json:"users"`
}

func GetNearUsersHandler(w http.ResponseWriter, r *http.Request) {
	var input GetNearUsersInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	if input.X == 0 && input.Y == 0 {
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	var response GetNearUsersReturn
	response.Users, err = dbGetNearbyUsers(input, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

type GetPossibleContactsReturn struct {
	Users []PossibleContact `json:"users"`
}

func GetPossibleContactsHandler(w http.ResponseWriter, r *http.Request) {
	var account AccountInfo
	err := share.ReadInput(r, &account)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	var response GetPossibleContactsReturn
	response.Users, err = dbGetPossibleContacts(account.UserID, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

type GetPhotosInput struct {
	CIDs []uint64 `json:"cids"`
}

func GetPhotosHandler(w http.ResponseWriter, r *http.Request) {
	var input GetPhotosInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	numIDs := len(input.CIDs)
	if numIDs == 0 || numIDs > 100 {
		share.WriteError(w, 1)
		return
	}

	var lens []int
	var datas [][]byte

	for _, cID := range input.CIDs {
		path := filepath.Join("photos", strconv.FormatUint(cID, 10)+".png")
		file, err := os.Open(path)
		if err != nil {
			share.WriteError(w, 1)
			return
		}
		defer file.Close()

		data, err := ioutil.ReadAll(file)
		if err != nil {
			share.WriteError(w, 1)
			return
		}

		len := len(data)

		if len == 0 {
			share.WriteError(w, 1)
			return
		} else {
			lens = append(lens, len)
			datas = append(datas, data)
		}
	}

	share.WriteError(w, 0)
	w.Write([]byte{byte(numIDs)})

	for _, len := range lens {
		share.WriteU32(w, uint32(len))
	}

	for _, data := range datas {
		w.Write(data)
	}
}

type SearchContactInput struct {
	User uint64 `json:"user"`
	Key  string `json:"key"`
}

type SearchContactReturn struct {
	User uint64 `json:"user"`
	Name string `json:"name"`
}

func SearchContactHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var input SearchContactInput
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: connect db error")
		return
	}
	defer c.Close()

	contactID, err := dbSearchContact(input.User, input.Key, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	accountKey := GetAccountKey(contactID)
	name, err := DbGetUserInfoField(accountKey, NameField, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var response SearchContactReturn
	response.User = contactID
	response.Name = name

	data, err := json.Marshal(&response)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	fmt.Fprintf(w, "%s", data)
}
