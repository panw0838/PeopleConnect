package share

import "strconv"

func GetRequestsKey(user uint64) string {
	return "requests:" + strconv.FormatUint(user, 10)
}

func GetGroupKey(gID uint32) string {
	return "group:" + strconv.FormatUint(uint64(gID), 10)
}

func GetUserGroupKey(uID uint64) string {
	return "groups:" + strconv.FormatUint(uID, 10)
}
