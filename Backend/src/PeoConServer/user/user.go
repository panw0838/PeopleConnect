package user

import (
	"database/sql"
	"fmt"

	_ "github.com/go-sql-driver/mysql"
)

const BLACKLIST_BIT uint16 = 1
const FAMILY_BIT uint16 = 2
const CLASSMATE_BIT uint16 = 4
const COWORKER_BIT uint16 = 8
const FRIEND_BIT uint16 = 16
const NORMAL_BIT uint16 = 32

type ContactInfo struct {
	userID   uint32
	group    uint32
	noteName string
}

type UserInfo struct {
	userID     uint32
	userName   string
	userPic    string
	cellNumber string
	password   string
	deviceID   string
	tagNames   string
}

const SqlServer = "user:123456@tcp(localhost:3306)/"

func AddUserInfo(userInfo UserInfo) {
	db, err := sql.Open("mysql", SqlServer+"UserTable")
	if err != nil {
		fmt.Println("Open Database Error:", err)
	}
	defer db.Close()

	writer, err := db.Prepare("INSERT INTO UserTable values(?,?,?,?,?,?,?);")
	if err != nil {
		fmt.Println("Prepare Error:", err)
	}
	defer writer.Close()

	writer.Exec(
		userInfo.userID,
		userInfo.userName,
		userInfo.userPic,
		userInfo.cellNumber,
		userInfo.password,
		userInfo.deviceID,
		userInfo.tagNames)
}

func GetUserInfo(userID uint32) UserInfo {
	db, err := sql.Open("mysql", SqlServer+"UserTable")
	if err != nil {
		fmt.Println("Open Database Error:", err)
	}
	defer db.Close()

	// Prepare statement for reading data
	reader, err := db.Prepare("SELECT * FROM UserTable WHERE userID = ?")
	if err != nil {
		fmt.Println("Prepare Database Error:", err)
	}
	defer reader.Close()

	var userInfo UserInfo
	err = reader.QueryRow(userID).Scan(
		&userInfo.userID,
		&userInfo.userID,
		&userInfo.userName,
		&userInfo.userPic,
		&userInfo.cellNumber,
		&userInfo.password,
		&userInfo.deviceID,
		&userInfo.tagNames)
	if err != nil {
		fmt.Println("Query Database Error:", err)
	}

	return userInfo
}

func AddFriend(user1 uint32, user2 uint32, flag1 uint32, flag2 uint32) {
	db, err := sql.Open("mysql", SqlServer+"FriendTable")
	if err != nil {
		fmt.Println("Open Database Error:", err)
	}
	defer db.Close()

	writer, err := db.Prepare("INSERT INTO FriendTable values(?,?,?,?);")
	if err != nil {
		fmt.Println("Prepare Error:", err)
	}
	defer writer.Close()

	writer.Exec(user1, user2, flag1, flag2)
}

func RemoveFriend(user1 uint32, user2 uint32) {
	db, err := sql.Open("mysql", SqlServer+"FriendTable")
	if err != nil {
		fmt.Println("Open Database Error:", err)
	}
	defer db.Close()

	writer, err := db.Prepare("DELETE FROM FriendTable where user1 = ? and user2 = ?;")
	if err != nil {
		fmt.Println("Prepare Error:", err)
	}
	defer writer.Close()

	writer.Exec(user1, user2)
}

func UpdateFriend(user1 uint32, user2 uint32, flag uint32) {
	db, err := sql.Open("mysql", SqlServer+"FriendTable")
	if err != nil {
		fmt.Println("Open Database Error:", err)
	}
	defer db.Close()

	var command string
	var _user1 uint32
	var _user2 uint32
	if user1 < user2 {
		_user1 = user1
		_user2 = user2
		command = "UPDATE FriendTable SET flag1 = ? WHERE user1 = ? and user2 = ?;"
	} else {
		_user1 = user2
		_user2 = user1
		command = "UPDATE FriendTable SET flag2 = ? WHERE user1 = ? and user2 = ?;"
	}
	writer, err := db.Prepare(command)
	if err != nil {
		fmt.Println("Prepare Error:", err)
	}
	defer writer.Close()

	writer.Exec(flag, _user1, _user2)
}
