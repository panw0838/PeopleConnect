package user

import (
	"encoding/json"
	"fmt"
	"share"
	"strings"

	"github.com/garyburd/redigo/redis"
)

const Max_Groups int = 3

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

func DbSetUserGroups(uID uint64, groups []string, c redis.Conn) error {
	var data UserGroups
	data.Groups = groups
	bytes, err := json.Marshal(data)
	if err != nil {
		return err
	}

	userKey := GetAccountKey(uID)
	_, err = c.Do("HSET", userKey, GroupsFiled, bytes)
	return err
}

func dbAddGroup(uID uint64, newGroup string, c redis.Conn) error {
	groups, err := DbGetUserGroups(uID, c)
	if err != nil {
		return err
	}

	if len(groups) >= Max_Groups {
		return fmt.Errorf("Reach max groups")
	}

	for _, group := range groups {
		if strings.Compare(group, newGroup) == 0 {
			return fmt.Errorf("Already in group")
		}
	}

	// check if groups valid
	univKey := share.GetUnviKey()
	exists, err := redis.Int(c.Do("SISMEMBER", univKey, newGroup))
	if err != nil {
		return err
	}
	if exists == 0 {
		return fmt.Errorf("No such group")
	}

	groups = append(groups, newGroup)
	err = DbSetUserGroups(uID, groups, c)

	return err
}
