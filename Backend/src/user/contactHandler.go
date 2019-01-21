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
		share.WriteErrorCode(w, err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	var response GetContactsReturn

	contacts, err := dbGetContacts(account.UserID, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	response.Contacts = contacts

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

type GetPostsUsersInput struct {
	UID  uint64   `json:"user"`
	CIDs []uint64 `json:"cids"`
}

type User struct {
	UID  uint64 `json:"user"`
	Name string `json:"name"`
}

type GetUsersReturn struct {
	Users []User `json:"users"`
}

func GetUsersHandler(w http.ResponseWriter, r *http.Request) {
	var input GetPostsUsersInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	var response GetUsersReturn

	for _, cID := range input.CIDs {
		var user User
		user.UID = cID
		user.Name, err = DbGetUserName(cID, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		response.Users = append(response.Users, user)
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
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
		share.WriteErrorCode(w, err)
		return
	}

	if input.X == 0 && input.Y == 0 {
		share.WriteErrorCode(w, err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	var response GetNearUsersReturn
	response.Users, err = dbGetNearbyUsers(input, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

type GetSuggestUsersReturn struct {
	Users []PossibleContact `json:"users"`
}

func GetSuggestUsersHandler(w http.ResponseWriter, r *http.Request) {
	var account AccountInfo
	err := share.ReadInput(r, &account)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	var response GetSuggestUsersReturn
	response.Users, err = dbGetPossibleContacts(account.UserID, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
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
		share.WriteErrorCode(w, err)
		return
	}

	numIDs := len(input.CIDs)
	if numIDs == 0 || numIDs > 100 {
		share.WriteErrorCode(w, err)
		return
	}

	var lens []int
	var datas [][]byte

	for _, cID := range input.CIDs {
		path := filepath.Join("photos", strconv.FormatUint(cID, 10)+".png")
		file, err := os.Open(path)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		defer file.Close()

		data, err := ioutil.ReadAll(file)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		len := len(data)

		if len == 0 {
			share.WriteErrorCode(w, err)
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

type SearchUsersInput struct {
	User        uint64   `json:"user"`
	CountryCode int      `json:"code"`
	Names       []string `json:"names"`
	CellNumbers []string `json:"cells"`
}

type SearchUsersReturn struct {
	Users []User `json:"users"`
}

func SearchUsersHandler(w http.ResponseWriter, r *http.Request) {
	var input SearchUsersInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	var response SearchUsersReturn

	for idx, cell := range input.CellNumbers {
		cID, err := dbGetUser(input.CountryCode, cell, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		if cID == 0 {
			continue
		}

		isStranger, err := IsStranger(cID, input.User, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		if !isStranger {
			continue
		}

		var newUser User
		newUser.UID = cID
		newUser.Name = input.Names[idx]
		response.Users = append(response.Users, newUser)
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteErrorCode(w, nil)
	w.Write(data)
}

type NoteContactInput struct {
	UID  uint64 `json:"uid"`
	CID  uint64 `json:"cid"`
	Name string `json:"name"`
}

func NoteContactHandler(w http.ResponseWriter, r *http.Request) {
	var input NoteContactInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	nameSize := len(input.Name)
	if nameSize == 0 || nameSize > NAME_SIZE {
		share.WriteErrorCode(w, fmt.Errorf("NoteContactHandler, invalid note name %s", input.Name))
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	isFriend, err := IsFriend(input.UID, input.CID, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	if !isFriend {
		share.WriteErrorCode(w, fmt.Errorf("NoteContactHandler, not friend %d %d", input.UID, input.CID))
		return
	}

	err = dbSetName(input.UID, input.CID, input.Name)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteErrorCode(w, nil)
}
