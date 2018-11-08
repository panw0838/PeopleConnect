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

	fatherID, err := strconv.ParseUint(r.FormValue("tagfatherid"), 16, 32)
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

	err = dbAddTagPrecheck(userID, fatherID, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	tagIdx, err := dbAddTag(userID, fatherID, tagname, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	tagID := tagIdx + USER_TAG_START

	numMembers, err := strconv.ParseUint(r.FormValue("nummembers"), 16, 32)
	if err != nil {
		fmt.Fprintf(w, "Error: Invalid num members")
		return
	}

	if numMembers != 0 {
		tagBits := (ONE_64<<tagID | ONE_64<<fatherID)
		members := make([]uint64, numMembers, 0)
		for i := 0; i < int(numMembers); i++ {
			membername := "member" + string(i)
			members[i], err = strconv.ParseUint(r.FormValue(membername), 16, 32)
			if err != nil {
				fmt.Fprintf(w, "Error: Invalid member")
				return
			} else {
				dbEnableBits(userID, members[i], tagBits, c)
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
	if err != nil || isSystemTag(tagID) {
		fmt.Fprintf(w, "Error: Invalid tag")
		return
	}

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		fmt.Println("Connect to redis error", err)
		return
	}
	defer c.Close()

	hasSon, err := dbCheckSubTag(userID, tagID, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	} else if hasSon {
		fmt.Fprintf(w, "Error: Tag has sub group")
		return
	}

	hasMember, err := dbHasMember(userID, tagID, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	} else if hasMember {
		fmt.Fprintf(w, "Error: Tag has members")
		return
	}

	err = dbRemTag(userID, tagID, c)
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

	if !isSystemTag(tagID) && !isUserTag(tagID) {
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
	if isUserTag(tagID) {
		exists, err := dbUserTagExists(userID, tagID, c)
		if err != nil {
			fmt.Fprintf(w, "Error: %v", err)
			return
		}
		if !exists {
			fmt.Fprintf(w, "Error: Invalid tag")
			return
		}
	}

	numNewMembers, err := strconv.ParseUint(r.FormValue("numAddMember"), 16, 32)
	if err == nil {
		tagBits, err := getTagBits(userID, tagID, c)
		if err != nil {
			fmt.Fprintf(w, "Error: %v", err)
			return
		}

		for i := 0; i < int(numNewMembers); i++ {
			membername := "newMember" + string(i)
			contact, err := strconv.ParseUint(r.FormValue(membername), 16, 32)
			if err != nil {
				fmt.Fprintf(w, "Error: Invalid member")
				return
			} else {
				dbEnableBits(userID, contact, tagBits, c)
			}
		}
	}

	numDelMembers, err := strconv.ParseUint(r.FormValue("numDelMember"), 16, 32)
	if err == nil {
		tagBits := (ONE_64 << tagID)
		for i := 0; i < int(numDelMembers); i++ {
			membername := "delMember" + string(i)
			contact, err := strconv.ParseUint(r.FormValue(membername), 16, 32)
			if err != nil {
				fmt.Fprintf(w, "Error: Invalid member")
				return
			} else {
				dbDisableBits(userID, contact, tagBits, c)
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
