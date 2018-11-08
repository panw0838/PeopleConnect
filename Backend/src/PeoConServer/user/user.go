package user

type UserInfo struct {
	// values in database
	UserID      uint64
	QQNumber    string // query
	CellNumber  string // query
	MailAddress string // query
	Account     string // query

	Config   uint64
	UserName string
	Password string
	DeviceID string
}

func GetUserPicPath(userID uint32) string {
	return string(userID) + ".png"
}
