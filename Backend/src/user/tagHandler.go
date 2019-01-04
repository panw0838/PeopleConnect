package user

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"share"

	"github.com/garyburd/redigo/redis"
)

type AddTagParams struct {
	User   uint64 `json:"user"`
	Father uint8  `json:"father"`
	Name   string `json:"name"`
}

type AddTagReturn struct {
	Tag uint8 `json:"tag"`
}

func AddTagHandler(w http.ResponseWriter, r *http.Request) {
	var params AddTagParams
	err := share.ReadInput(r, &params)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var nameLen = len(params.Name)
	if nameLen > int(NAME_SIZE) || nameLen <= 0 {
		share.WriteErrorCode(w, err)
		return
	}

	if !isValidSysTag(params.Father) {
		share.WriteErrorCode(w, err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	tagIdx, err := dbAddTag(params.User, params.Father, params.Name, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var returnData AddTagReturn
	returnData.Tag = tagIdx
	data, err := json.Marshal(&returnData)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

type RemTagInput struct {
	User uint64 `json:"user"`
	Tag  uint8  `json:"tag"`
}

func RemTagHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var input RemTagInput
	err = json.Unmarshal(body, &input)
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

	err = dbRemTag(input.User, input.Tag, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
}

type UpdateTagMemberInput struct {
	User      uint64   `json:"user"`
	Tag       uint8    `json:"tag"`
	SystemTag bool     `json:"sys"`
	Add       []uint64 `json:"add"`
	Rem       []uint64 `json:"rem"`
}

func UpdateTagMemberHandler(w http.ResponseWriter, r *http.Request) {
	var input UpdateTagMemberInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	if input.SystemTag {
		if !isValidSysTag(input.Tag) {
			share.WriteErrorCode(w, err)
			return
		}
	} else {
		if uint64(input.Tag) > MAX_USR_TAGS {
			share.WriteErrorCode(w, err)
			return
		}
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	err = dbMoveTagMembers(input, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
}

func updateTagNameHandler(w http.ResponseWriter, r *http.Request) {
	// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "Error: ParseForm err: %v", err)
		return
	}
}
