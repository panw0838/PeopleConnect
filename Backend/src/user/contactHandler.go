package user

import (
	"encoding/binary"
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
	Tags     []TagInfo     `json:"tags"`
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

	tags, err := dbGetTags(account.UserID, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	response.Tags = tags

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

type GetPostsUsersReturn struct {
	Users []PostUser `json:"users"`
}

func GetPostsUsersHandler(w http.ResponseWriter, r *http.Request) {
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

	var response GetPostsUsersReturn

	for _, cID := range input.CIDs {
		var user PostUser

		name, err := dbGetUserName(cID, c)
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
		var bufU32 = make([]byte, 4)
		binary.LittleEndian.PutUint32(bufU32, uint32(len))
		w.Write(bufU32)
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

type AddContactInput struct {
	User    uint64 `json:"user"`
	Contact uint64 `json:"contact"`
	Flag    uint64 `json:"flag"`
	Name    string `json:"name"`
}

func AddContactHandler(w http.ResponseWriter, r *http.Request) {
	var input AddContactInput
	err := share.ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}

	err = AddContactPreCheck(input.User, input.Contact, input.Flag, input.Name)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: connect db error")
		return
	}
	defer c.Close()

	requestKey := share.GetRequestKey(input.Contact, input.User)
	exists, err := redis.Int64(c.Do("EXISTS", requestKey))
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	if exists == 0 {
		fmt.Fprintf(w, "Error: request not exist")
		return
	}

	err = dbAddContact(input.User, input.Contact, input.Flag, input.Name, c)
	if err != nil {
		fmt.Fprintf(w, "Error, %v", err)
	}

	fmt.Fprintf(w, "Success")
}

type RemContactInput struct {
	User    uint64 `json:"user"`
	Contact uint64 `json:"contact"`
}

func RemContactHandler(w http.ResponseWriter, r *http.Request) {
	var input RemContactInput
	err := share.ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}

	err = dbRemoveContact(input.User, input.Contact)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "Success")
}
