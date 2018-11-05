package user

type UserInfo struct {
	// values in database
	UserID     uint32
	UserName   string
	CellNumber string
	Password   string
	DeviceID   string
	TagNames   string

	// values in cache
	ContactsRing    uint32
	NewContactsRing uint32
}

func GetUserPicPath(userID uint32) string {
	return string(userID) + ".png"
}

// contact file format
// numCountacts -> contact1 -> contact2 -> ...
func GetUserContactsPath(userID uint32) string {
	return string(userID) + ".ctc"
}
