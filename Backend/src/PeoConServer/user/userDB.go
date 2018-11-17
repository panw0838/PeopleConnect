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

func getAccountKey(userID uint64) string {
	return "user:" + strconv.FormatUint(userID, 10)
}

func getAccountID(account string) (uint64, error) {
	userID, err := strconv.Atoi(account[5:])
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

	accountKey := getAccountKey(newID)
	_, err = c.Do("HMSET", accountKey,
		UserField, accountKey,
		CellFiled, info.CellNumber,
		MailField, "",
		QQField, "",
		NameField, info.CellNumber,
		DeviceField, info.Device,
		ConfigField, 0,
		PassField, info.Password)
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

func dbVerifyUser(loginInfo LoginInfo, c redis.Conn) (uint64, error) {
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

	password, err := dbGetUserInfoField(accountKey, PassField, c)
	if err != nil {
		return 0, err
	}

	userID, err := getAccountID(accountKey)
	if err != nil {
		return 0, err
	}

	if strings.Compare(password, loginInfo.Password) == 0 {
		return userID, nil
	} else {
		return 0, fmt.Errorf("password not correct")
	}
}

func dbGetUserInfoField(accountKey string, filed string, c redis.Conn) (string, error) {
	values, err := redis.Values(c.Do("HMGET", accountKey, filed))
	value, err := redis.String(values[0], err)
	if err != nil {
		return "", err
	}

	return value, nil
}

func dbUpdateUserInfo(userInfo UserInfo, c redis.Conn) error {
	_, err := c.Do("MULTI")
	if err != nil {
		return err
	} else {
		accountKey := getAccountKey(userInfo.UserID)
		_, err = c.Do("HMSET", accountKey,
			UserField, accountKey,
			CellFiled, userInfo.CellNumber,
			MailField, userInfo.MailAddress,
			QQField, userInfo.QQNumber,
			NameField, userInfo.UserName,
			DeviceField, userInfo.DeviceID,
			ConfigField, userInfo.Config,
			PassField, userInfo.Password)
		if err != nil {
			return err
		}

		if len(userInfo.CellNumber) != 0 {
			cellKey := getCellKey(userInfo.CellNumber)
			exists, err := redis.Bool(c.Do("EXISTS", cellKey))
			if err != nil {
				return err
			}
			if exists {
				return fmt.Errorf("cell number exists")
			} else {
				c.Do("SET", cellKey, accountKey)
			}
		}

		_, err = c.Do("EXEC")
		if err != nil {
			return err
		}
	}
	return nil
}

func GetUserInfo(userID uint64, c redis.Conn) (UserInfo, error) {
	var userInfo UserInfo
	accountKey := getAccountKey(userID)

	values, err := redis.Values(c.Do("HMGET", accountKey,
		UserField,
		CellFiled,
		MailField,
		QQField,
		NameField,
		PassField,
		ConfigField,
		DeviceField))
	if err != nil {
		return userInfo, err
	}

	userInfo.UserID, err = redis.Uint64(values[0], err)
	if err != nil {
		return userInfo, err
	}
	userInfo.CellNumber, err = redis.String(values[1], err)
	if err != nil {
		return userInfo, err
	}
	userInfo.MailAddress, err = redis.String(values[2], err)
	if err != nil {
		return userInfo, err
	}
	userInfo.QQNumber, err = redis.String(values[3], err)
	if err != nil {
		return userInfo, err
	}
	userInfo.UserName, err = redis.String(values[4], err)
	if err != nil {
		return userInfo, err
	}
	userInfo.Password, err = redis.String(values[5], err)
	if err != nil {
		return userInfo, err
	}
	userInfo.Config, err = redis.Uint64(values[6], err)
	if err != nil {
		return userInfo, err
	}
	userInfo.DeviceID, err = redis.String(values[7], err)
	if err != nil {
		return userInfo, err
	}

	return userInfo, nil
}
