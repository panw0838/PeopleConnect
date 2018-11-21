package user

import (
	"fmt"
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

func trimIPString(rawStr string) string {
	idx := strings.Index(rawStr, ":")
	return rawStr[0:idx]
}

func GetAccountKey(userID uint64) string {
	return "user:" + strconv.FormatUint(userID, 10)
}

func getAccountID(account string) (uint64, error) {
	userID, err := strconv.ParseUint(account[5:], 10, 64)
	if err != nil {
		return 0, err
	}
	return uint64(userID), nil
}

func getCellKey(cellNumber string) string {
	return "cell:" + cellNumber
}

func dbRegistry(info RegistryInfo, c redis.Conn) (uint64, error) {
	cellKey := getCellKey(info.CellNumber)
	exists, err := redis.Int64(c.Do("EXISTS", cellKey))
	if err != nil {
		return 0, err
	}
	if exists == 1 {
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
		NameField, info.CellNumber,
		DeviceField, info.Device,
		ConfigField, 0,
		PassField, info.Password,
		IPField, "")
	if err != nil {
		return 0, err
	}

	// add cell number to search table
	_, err = c.Do("SET", cellKey, accountKey)
	if err != nil {
		return 0, err
	}

	_, err = c.Do("EXEC")
	if err != nil {
		return 0, err
	}

	return newID, nil
}

func dbLogon(loginInfo LoginInfo, c redis.Conn) (uint64, error) {
	cellKey := getCellKey(loginInfo.CellNumber)
	exists, err := redis.Int64(c.Do("EXISTS", cellKey))
	if err != nil {
		return 0, err
	}
	if exists == 0 {
		return 0, fmt.Errorf("account not exists")
	}

	accountKey, err := redis.String(c.Do("GET", cellKey))
	if err != nil {
		return 0, err
	}

	password, err := DbGetUserInfoField(accountKey, PassField, c)
	if err != nil {
		return 0, err
	}

	userID, err := getAccountID(accountKey)
	if err != nil {
		return 0, err
	}

	if strings.Compare(password, loginInfo.Password) == 0 {
		_ = DbSetUserInfoField(accountKey, IPField, loginInfo.IPAddress, c)
		return userID, nil
	} else {
		return 0, fmt.Errorf("password not correct")
	}
}

func DbGetUserInfoField(accountKey string, filed string, c redis.Conn) (string, error) {
	values, err := redis.Values(c.Do("HMGET", accountKey, filed))
	value, err := redis.String(values[0], err)
	if err != nil {
		return "", err
	}

	return value, nil
}

func DbSetUserInfoField(accountKey string, filed string, value string, c redis.Conn) error {
	_, err := c.Do("HMSET", accountKey, filed, value)
	if err != nil {
		return err
	}
	return nil
}
