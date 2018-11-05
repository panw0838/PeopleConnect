package user

import (
	"database/sql"
	"fmt"

	_ "github.com/go-sql-driver/mysql"
)

const SqlServer = "mysql:123456@tcp(localhost:3306)/"
const UserDataBase = "userdatabase"

func GetUserTable(userID uint32) string {
	return "usertable" + string(userID%10)
}

func CreateUserTable(tableID int) {
	tableName := "usertable" + string(tableID)
	db, err := sql.Open("mysql", SqlServer)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	_, err = db.Exec("CREATE DATABASE " + UserDataBase)
	_, err = db.Exec("USE " + UserDataBase)
	if err != nil {
		panic(err)
	}

	_, err = db.Exec("CREATE TABLE " + tableName + " ( " +
		"userID int unsigned, " +
		"userName varchar(36), " +
		"cellNumber varchar(16), " +
		"password varchar(16), " +
		"deviceID varchar(16), " +
		"tagNames varchar(200))")
	if err != nil {
		panic(err)
	}
}

func CreateUserTables() {
	for i := 0; i < 10; i++ {
		CreateUserTable(i)
	}
}

func AddUserInfo(userInfo UserInfo) {
	tableName := GetUserTable(userInfo.UserID)
	db, err := sql.Open("mysql", SqlServer+UserDataBase)
	if err != nil {
		fmt.Println("Open Database Error:", err)
	}
	defer db.Close()

	writer, err := db.Prepare("INSERT INTO " + tableName + " values(?,?,?,?,?,?,?);")
	if err != nil {
		fmt.Println("Prepare Error:", err)
	}
	defer writer.Close()

	writer.Exec(
		userInfo.UserID,
		userInfo.UserName,
		userInfo.CellNumber,
		userInfo.Password,
		userInfo.DeviceID,
		userInfo.TagNames)
}

func GetUserInfo(userID uint32) UserInfo {
	tableName := GetUserTable(userID)
	db, err := sql.Open("mysql", SqlServer+UserDataBase)
	if err != nil {
		fmt.Println("Open Database Error:", err)
	}
	defer db.Close()

	// Prepare statement for reading data
	reader, err := db.Prepare("SELECT * FROM " + tableName +
		" WHERE userID = ?")
	if err != nil {
		fmt.Println("Prepare Database Error:", err)
	}
	defer reader.Close()

	var userInfo UserInfo
	err = reader.QueryRow(userID).Scan(
		&userInfo.UserID,
		&userInfo.UserName,
		&userInfo.CellNumber,
		&userInfo.Password,
		&userInfo.DeviceID,
		&userInfo.TagNames)
	if err != nil {
		fmt.Println("Query Database Error:", err)
	}

	return userInfo
}
