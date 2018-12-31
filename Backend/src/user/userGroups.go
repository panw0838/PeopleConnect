package user

import (
	"encoding/json"
	"fmt"

	"github.com/garyburd/redigo/redis"
)

const Max_Groups int = 5

type UserGroups struct {
	Groups []uint32 `json:"groups"`
}

func DbGetUserGroups(uID uint64, c redis.Conn) ([]uint32, error) {
	userKey := GetAccountKey(uID)
	bytes, err := redis.Bytes(c.Do("HGET", userKey, GroupsFiled))
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

	_, err = c.Do("HSET", userKey, GroupsFiled, bytes)
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

	if len(groups) >= Max_Groups {
		return fmt.Errorf("Reach max groups")
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
