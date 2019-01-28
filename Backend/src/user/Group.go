package user

import (
	"encoding/json"
	"fmt"
	"net/http"
	"share"
	"strings"
	"time"
	"univ"

	"github.com/garyburd/redigo/redis"
)

const Max_Groups int = 3

type UserGroup struct {
	ID   uint32 `json:"id"`
	Name string `json:"name"`
}

type UserGroups struct {
	Groups []string `json:"groups"`
}

func DbGetUserGroups(uID uint64, c redis.Conn) ([]string, error) {
	userKey := GetAccountKey(uID)
	value, err := c.Do("HGET", userKey, GroupsFiled)
	if err != nil {
		return nil, err
	}
	if value == nil {
		return nil, nil
	}

	bytes, err := redis.Bytes(value, err)
	if err != nil {
		return nil, err
	}
	if len(bytes) == 0 {
		return nil, nil
	}

	var groups UserGroups
	err = json.Unmarshal(bytes, &groups)
	if err != nil {
		return nil, err
	}

	return groups.Groups, nil
}

func dbAddGroup(uID uint64, newGroup string, year int, c redis.Conn) (uint32, error) {
	groups, err := DbGetUserGroups(uID, c)
	if err != nil {
		return 0, err
	}

	if len(groups) >= Max_Groups {
		return 0, fmt.Errorf("Reach max groups")
	}

	for _, group := range groups {
		if strings.Compare(group, newGroup) == 0 {
			return 0, fmt.Errorf("Already in group")
		}
	}

	// check if groups valid
	univKey := share.GetUnviKey()
	val, err := c.Do("ZSCORE", univKey, newGroup)
	if err != nil {
		return 0, err
	}
	if val == nil {
		return 0, fmt.Errorf("No such group")
	}

	// check year
	now := time.Now()
	thisYear, _, _ := now.Date()
	if year < 1930 || year > thisYear {
		return 0, fmt.Errorf("Wrong entry year")
	}

	groups = append(groups, newGroup)
	var data UserGroups
	data.Groups = groups
	bytes, err := json.Marshal(data)
	if err != nil {
		return 0, err
	}

	_, err = c.Do("MULTI")
	if err != nil {
		return 0, err
	}

	err = univ.DbAddUnivMember(newGroup, uID, year, c)
	if err != nil {
		return 0, err
	}

	userKey := GetAccountKey(uID)
	_, err = c.Do("HSET", userKey, GroupsFiled, bytes)

	_, err = c.Do("EXEC")
	if err != nil {
		return 0, err
	}

	channel, err := share.GetChannel(newGroup, c)
	if err != nil {
		return 0, err
	}

	return channel, nil
}

type AddGroupInput struct {
	UID  uint64 `json:"uid"`
	Name string `json:"name"`
	Year int    `json:"year"`
}

type AddGroupReturn struct {
	GID uint32 `json:"id"`
}

func AddGroupHandler(w http.ResponseWriter, r *http.Request) {
	var input AddGroupInput
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

	var response AddGroupReturn
	response.GID, err = dbAddGroup(input.UID, input.Name, input.Year, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteErrorCode(w, nil)
	w.Write(data)
}

type SearchGroupInput struct {
	UID  uint64 `json:"uid"`
	Name string `json:"name"`
}

type SearchGroupReturn struct {
	Names []string `json:"names"`
}

func SearchGroupHandler(w http.ResponseWriter, r *http.Request) {
	var input SearchGroupInput
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

	var response SearchGroupReturn
	response.Names = share.Search(input.Name)
	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	share.WriteErrorCode(w, nil)
	w.Write(data)
}
