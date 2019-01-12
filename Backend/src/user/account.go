package user

import (
	"fmt"
	"share"
	"strconv"
	"strings"

	"github.com/garyburd/redigo/redis"
)

const AccountDB = "127.0.0.1:6379"

const NewUIDKey = "newuserid"

const UserField = "uid"
const CellFiled = "cell"
const MailField = "mail"
const QQField = "qq"
const DeviceField = "device"
const ConfigField = "config"
const PassField = "pass"
const IPField = "ip"
const XFiled = "x"
const YFiled = "y"
const GroupsFiled = "groups"
const TagsField = "tags"

func GetAccountKey(userID uint64) string {
	return "user:" + strconv.FormatUint(userID, 10)
}

func getSearchTable(contryCode int) string {
	return "cell:" + strconv.FormatInt(int64(contryCode), 10)
}

func getAccountID(account string) (uint64, error) {
	userID, err := strconv.ParseUint(account[5:], 10, 64)
	if err != nil {
		return 0, err
	}
	return uint64(userID), nil
}

func dbGetUser(contryCode int, cellNumber string, c redis.Conn) (uint64, error) {
	// get search table
	searchTable := getSearchTable(contryCode)
	value, err := c.Do("ZSCORE", searchTable, cellNumber)
	if err != nil {
		return 0, err
	}
	if value == nil {
		return 0, nil
	}

	uID, err := share.GetUint64(value, err)
	if err != nil {
		return 0, err
	}

	return uID, nil
}

func dbRegistry(info RegistryInfo, c redis.Conn) (uint64, error) {
	exists, err := dbGetUser(info.CountryCode, info.CellNumber, c)
	if err != nil {
		return 0, err
	}
	if exists != 0 {
		return 0, fmt.Errorf("Account exists")
	}

	newID, err := redis.Uint64(c.Do("INCR", NewUIDKey))
	if err != nil {
		return 0, err
	}

	_, err = c.Do("MULTI")
	if err != nil {
		return 0, err
	}

	accountKey := GetAccountKey(newID)
	_, err = c.Do("HMSET", accountKey,
		UserField, accountKey,
		CellFiled, info.CellNumber,
		MailField, "",
		QQField, "",
		NameField, info.UserName,
		DeviceField, info.Device,
		ConfigField, 0,
		PassField, info.Password,
		IPField, "")
	if err != nil {
		return 0, err
	}

	// add cell number to search table
	searchTable := getSearchTable(info.CountryCode)
	_, err = c.Do("ZADD", searchTable, newID, info.CellNumber)
	if err != nil {
		return 0, err
	}

	_, err = c.Do("EXEC")
	if err != nil {
		return 0, err
	}

	return newID, nil
}

func dbLogon(info LoginInfo, c redis.Conn) (uint64, error) {
	uID, err := dbGetUser(info.CountryCode, info.CellNumber, c)
	if err != nil {
		return 0, err
	}
	if uID == 0 {
		return 0, fmt.Errorf("Account not exists")
	}

	accountKey := GetAccountKey(uID)

	password, err := DbGetUserInfoField(accountKey, PassField, c)
	if err != nil {
		return 0, err
	}

	if strings.Compare(password, info.Password) == 0 {
		_ = DbSetUserInfoField(accountKey, DeviceField, info.Device, c)
		return uID, nil
	} else {
		return 0, fmt.Errorf("password not correct")
	}
}

func DbGetUserInfoField(accountKey string, filed string, c redis.Conn) (string, error) {
	value, err := redis.String(c.Do("HGET", accountKey, filed))
	if err != nil {
		return "", err
	}

	return value, nil
}

func DbGetUserName(uID uint64, c redis.Conn) (string, error) {
	userKey := GetAccountKey(uID)
	name, err := redis.String(c.Do("HGET", userKey, NameField))
	if err != nil {
		return "", err
	} else {
		return name, nil
	}
}

func dbSetUserPosition(uID uint64, x float64, y float64, c redis.Conn) error {
	userKey := GetAccountKey(uID)
	_, err := c.Do("HMSET", userKey, XFiled, x, YFiled, y)
	return err
}

func dbGetUserPosition(uID uint64, c redis.Conn) (float64, float64, error) {
	userKey := GetAccountKey(uID)
	values, err := redis.Values(c.Do("HMGET", userKey, XFiled, YFiled))
	x, err := redis.Float64(values[0], err)
	y, err := redis.Float64(values[1], err)
	if err != nil {
		return 0, 0, err
	} else {
		return x, y, nil
	}
}

func DbSetUserInfoField(accountKey string, filed string, value string, c redis.Conn) error {
	_, err := c.Do("HMSET", accountKey, filed, value)
	if err != nil {
		return err
	}
	return nil
}
