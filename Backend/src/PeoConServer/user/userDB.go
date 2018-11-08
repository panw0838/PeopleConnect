package user

import (
	"fmt"
	"strconv"

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
	return strconv.FormatUint(userID, 16)
}

func getCellKey(cellNumber string) string {
	return "cell:" + cellNumber
}

func dbRegiste(cellNumber string, device string, c redis.Conn) (uint64, error) {
	cellKey := getCellKey(cellNumber)
	exists, err := redis.Bool(c.Do("EXISTS", cellKey))
	if err != nil {
		return 0, err
	}
	if exists {
		return 0, fmt.Errorf("Account exists")
	}

	_, err = c.Do("MULTI")
	if err != nil {
		return 0, err
	}

	// double check
	exists, err = redis.Bool(c.Do("EXISTS", cellKey))
	if err != nil {
		return 0, err
	}
	if exists {
		return 0, fmt.Errorf("Account exists")
	}

	newID, err := redis.Uint64(c.Do("GET", NewUIDKey))
	if err != nil {
		return 0, err
	}

	accountKey := getAccountKey(newID)
	_, err = c.Do("HMSET", accountKey,
		UserField, accountKey,
		CellFiled, cellNumber,
		MailField, "",
		QQField, "",
		NameField, cellNumber,
		DeviceField, device,
		ConfigField, 0,
		PassField, "")
	if err != nil {
		return 0, err
	}

	// add cell number to search table
	_, err = c.Do("SET", cellKey, accountKey)
	if err != nil {
		return 0, err
	}

	// update new user id
	_, err = c.Do("SET", NewUIDKey, newID+1)
	if err != nil {
		return 0, err
	}

	_, err = c.Do("EXEC")
	if err != nil {
		return 0, err
	}

	return newID, nil
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
