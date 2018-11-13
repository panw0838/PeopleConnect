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

type RegistryInfo struct {
	CellNumber string `json:"cell"`
	CellCode   string `json:"code,omitempty"`
	Password   string `json:"pass,omitempty"`
	Device     string `json:"device"`
}

type LoginInfo struct {
	CellNumber string `json:"cell"`
	CellCode   string `json:"code,omitempty"`
	Password   string `json:"pass,omitempty"`
	Device     string `json:"device"`
}

type LogonFeedbackInfo struct {
	UserID uint64 `json:"user"`
}

func GetUserPicPath(userID uint32) string {
	return string(userID) + ".png"
}
