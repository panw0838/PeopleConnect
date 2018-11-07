package user

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

func createTagHandler(w http.ResponseWriter, r *http.Request) {
	// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "Error: ParseForm err: %v", err)
		return
	}

	tagname := r.FormValue("tagname")

	if len(tagname) > int(NAME_SIZE) {
		fmt.Println(w, "Error: Invalid tag name")
		return
	}

	userID, err := strconv.ParseUint(r.FormValue("user"), 16, 32)
	if err != nil {
		fmt.Fprintf(w, "Error: Invalid user")
		return
	}

	fatherID, err := strconv.ParseInt(r.FormValue("tagfatherid"), 16, 32)
	if err != nil {
		fmt.Fprintf(w, "Error: Invalid father id")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	err = dbAddTagPrecheck(uint32(userID), uint32(fatherID), c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	tagIdx, err := dbAddTag(uint32(userID), byte(fatherID), tagname, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	tagID := uint32(tagIdx) + USER_TAG_START

	numMembers, err := strconv.ParseUint(r.FormValue("nummembers"), 16, 32)
	if err != nil {
		fmt.Fprintf(w, "Error: Invalid num members")
		return
	}

	if numMembers != 0 {
		tagBits := getTagBits(tagID, uint32(fatherID))
		members := make([]uint64, numMembers, 0)
		for i := 0; i < int(numMembers); i++ {
			membername := "member" + string(i)
			members[i], err = strconv.ParseUint(r.FormValue(membername), 16, 32)
			if err != nil {
				fmt.Fprintf(w, "Error: Invalid member")
				return
			} else {
				dbEnableBits(uint32(userID), uint32(members[i]), tagBits, c)
			}
		}
	}

	fmt.Fprintf(w, "Success: new tag %d", tagID)
}

func removeTagHandler(w http.ResponseWriter, r *http.Request) {
	// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "Error: ParseForm err: %v", err)
		return
	}

	userID, err := strconv.ParseUint(r.FormValue("user"), 16, 32)
	if err != nil {
		fmt.Fprintf(w, "Error: Invalid user")
		return
	}

	tagID, err := strconv.ParseUint(r.FormValue("tag"), 16, 32)
	if err != nil || tagID < uint64(USER_TAG_START) {
		fmt.Fprintf(w, "Error: Invalid tag")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	hasSon, err := dbCheckSubTag(uint32(userID), uint32(tagID), c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	} else if hasSon {
		fmt.Fprintf(w, "Error: Tag has sub group")
		return
	}

	hasMember, err := dbCheckMember(uint32(userID), uint32(tagID), c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	} else if hasMember {
		fmt.Fprintf(w, "Error: Tag has members")
		return
	}

	err = dbRemTag(uint32(userID), uint32(tagID), c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "Success")
}

func updateTagMemberHandler(w http.ResponseWriter, r *http.Request) {
	// Call ParseForm() to parse the raw query and update r.PostForm and r.Form.
	if err := r.ParseForm(); err != nil {
		fmt.Fprintf(w, "Error: ParseForm err: %v", err)
		return
	}

	userID, err := strconv.ParseUint(r.FormValue("user"), 16, 32)
	if err != nil {
		fmt.Fprintf(w, "Error: Invalid user")
		return
	}

	tagID, err := strconv.ParseUint(r.FormValue("tag"), 16, 32)
	if err != nil {
		fmt.Fprintf(w, "Error: Invalid tag")
		return
	}
	if !isSystemTag(uint32(tagID)) && !isUserTag(uint32(tagID)) {
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
	if isUserTag(uint32(tagID)) {
		exists, err := dbUserTagExists(uint32(userID), uint32(tagID), c)
		if err != nil {
			fmt.Fprintf(w, "Error: %v", err)
			return
		}
		if !exists {
			fmt.Fprintf(w, "Error: Invalid tag")
			return
		}
	}

	tagBits := uint32(1 << tagID)

	numNewMembers, err := strconv.ParseUint(r.FormValue("numAddMember"), 16, 32)
	if err == nil {
		for i := 0; i < int(numNewMembers); i++ {
			membername := "newMember" + string(i)
			contact, err := strconv.ParseUint(r.FormValue(membername), 16, 32)
			if err != nil {
				fmt.Fprintf(w, "Error: Invalid member")
				return
			} else {
				dbEnableBits(uint32(userID), uint32(contact), tagBits, c)
			}
		}
	}

	numDelMembers, err := strconv.ParseUint(r.FormValue("numDelMember"), 16, 32)
	if err == nil {
		for i := 0; i < int(numDelMembers); i++ {
			membername := "delMember" + string(i)
			contact, err := strconv.ParseUint(r.FormValue(membername), 16, 32)
			if err != nil {
				fmt.Fprintf(w, "Error: Invalid member")
				return
			} else {
				dbDisableBits(uint32(userID), uint32(contact), tagBits, c)
			}
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
