package user

type UserInfo struct {
	// values in database
	UserID     uint32
	UserName   string
	CellNumber string
	Password   string
	DeviceID   string
}

func GetUserPicPath(userID uint32) string {
	return string(userID) + ".png"
}
