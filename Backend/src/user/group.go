package user

import (
	"encoding/json"
	"fmt"

	"github.com/garyburd/redigo/redis"
)

type UserGroups struct {
	Groups []uint32 `json:"groups"`
}

func DbGetUserGroups(uID uint64, c redis.Conn) ([]uint32, error) {
	userKey := GetAccountKey(uID)
	values, err := redis.Values(c.Do("HMGET", userKey, GroupsFiled))
	bytes, err := redis.Bytes(values[0], err)
	if err != nil {
		return nil, err
	}

	var groups UserGroups
	err = json.Unmarshal(bytes, &groups)
	if err != nil {
		return nil, err
	}

	return groups.Groups, nil
}

func dbSetUserGroups(uID uint64, groups UserGroups, c redis.Conn) error {
	userKey := GetAccountKey(uID)

	bytes, err := json.Marshal(groups)
	if err != nil {
		return err
	}

	_, err = c.Do("HMSET", userKey, GroupsFiled, bytes)
	if err != nil {
		return err
	}

	return nil
}

func dbAddGroup(uID uint64, group uint32, c redis.Conn) error {
	groups, err := DbGetUserGroups(uID, c)
	if err != nil {
		return err
	}

	for _, gID := range groups {
		if gID == group {
			return fmt.Errorf("Already in group")
		}
	}

	var newGroup UserGroups
	newGroup.Groups = append(groups, group)

	err = dbSetUserGroups(uID, newGroup, c)

	return err
}
