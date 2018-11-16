package user

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/garyburd/redigo/redis"
)

type AddTagParams struct {
	User       uint64   `json:"user"`
	Father     uint8    `json:"father"`
	Name       string   `json:"name"`
	NumMembers uint     `json:"nummembers"`
	Members    []uint64 `json:"members"`
}

type AddTagReturn struct {
	Tag uint8 `json:"tag"`
}

func AddTagHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var params AddTagParams
	err = json.Unmarshal(body, &params)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	var nameLen = len(params.Name)
	if nameLen > int(NAME_SIZE) || nameLen <= 0 {
		fmt.Fprintf(w, "Error: Invalid tag name")
		return
	}

	if !isSystemTag(params.Father) && !isUserTag(params.Father) {
		fmt.Fprintf(w, "Error: Invalud father tag")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	err = dbAddTagPrecheck(params.User, params.Father, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	tagIdx, err := dbAddTag(params.User, params.Father, params.Name, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	tagID := tagIdx + USER_TAG_START
	tagBits := (ONE_64<<tagID | ONE_64<<params.Father)

	for _, member := range params.Members {
		err = dbEnableBits(params.User, member, tagBits, c)
		if err != nil {
			fmt.Fprintf(w, "Error: %v", err)
			return
		}
	}

	var returnData AddTagReturn
	returnData.Tag = uint8(tagID)
	data, err := json.Marshal(&returnData)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", data)
}

type RemTagInput struct {
	User uint64 `json:"user"`
	Tag  uint8  `json:"tag"`
}

func RemTagHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var input RemTagInput
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}

	if isSystemTag(input.Tag) {
		fmt.Fprintf(w, "Error: can't delete system tag")
		return
	}

	if !isUserTag(input.Tag) {
		fmt.Fprintf(w, "Error: Invalid tag")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	exists, err := dbUserTagExists(input.User, input.Tag, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	if !exists {
		fmt.Fprintf(w, "Error: tag not exists")
		return
	}

	hasSon, err := dbTagHasSubTag(input.User, input.Tag, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	} else if hasSon {
		fmt.Fprintf(w, "Error: Tag has sub group")
		return
	}

	hasMember, err := dbTagHasMember(input.User, input.Tag, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	} else if hasMember {
		fmt.Fprintf(w, "Error: Tag has members")
		return
	}

	err = dbRemTag(input.User, input.Tag, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "Success")
}

type UpdateTagMemberInput struct {
	User uint64   `json:"user"`
	Tag  uint8    `json:"tag"`
	Add  []uint64 `json:"add"`
	Rem  []uint64 `json:"rem"`
}

func UpdateTagMemberHandler(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "Error: read request")
		return
	}

	var input UpdateTagMemberInput
	err = json.Unmarshal(body, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error %s", body)
		return
	}

	if !isSystemTag(input.Tag) && !isUserTag(input.Tag) {
		fmt.Fprintf(w, "Error: Invalid tag")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	// check tag
	if isUserTag(input.Tag) {
		exists, err := dbUserTagExists(input.User, input.Tag, c)
		if err != nil {
			fmt.Fprintf(w, "Error: %v", err)
			return
		}
		if !exists {
			fmt.Fprintf(w, "Error: Invalid tag")
			return
		}
	}

	addBits, err := getTagAndFatherBits(input.User, input.Tag, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	for _, member := range input.Add {
		err := dbEnableBits(input.User, member, addBits, c)
		if err != nil {
			fmt.Fprintf(w, "Error: %v", err)
			return
		}
	}

	remBits, err := getTagAndSonsBits(input.User, input.Tag, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	for _, member := range input.Rem {
		err := dbDisableBits(input.User, member, remBits, c)
		if err != nil {
			fmt.Fprintf(w, "Error: %v", err)
			return
		}
	}

	fmt.Fprintf(w, "Success")
}

func updateTagNameHandler(w http.ResponseWriter, r *http.Request) {
	// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "Error: ParseForm err: %v", err)
		return
	}
}
