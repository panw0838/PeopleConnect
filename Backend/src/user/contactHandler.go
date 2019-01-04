package user

import (
	"encoding/json"
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

type SearchContactInput struct {
	User         uint64   `json:"user"`
	CountryCodes []int    `json:"codes"`
	CellNumbers  []string `json:"cells"`
}

type SearchContactReturn struct {
	Users []ContactInfo `json:"users"`
}

func SearchContactHandler(w http.ResponseWriter, r *http.Request) {
	var input SearchContactInput
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

	var response SearchContactReturn

	for idx, cell := range input.CellNumbers {
		cID, err := dbGetUser(input.CountryCodes[idx], cell, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		if cID == 0 {
			var nilContact ContactInfo
			nilContact.User = 0
			nilContact.Flag = 0
			nilContact.Name = ""
			response.Users = append(response.Users, nilContact)
			continue
		}

		flag, _, err := GetCashFlag(cID, input.User, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		if (flag & BLK_BIT) != 0 {
			var nilContact ContactInfo
			nilContact.User = 0
			nilContact.Flag = 0
			nilContact.Name = ""
			response.Users = append(response.Users, nilContact)
			continue
		}

		accountKey := GetAccountKey(cID)
		name, err := DbGetUserInfoField(accountKey, NameField, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		var newContact ContactInfo
		newContact.User = cID
		newContact.Flag = flag
		newContact.Name = name
		response.Users = append(response.Users, newContact)
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}
