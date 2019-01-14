package share

import "strconv"

func GetRequestsKey(user uint64) string {
	return "requests:" + strconv.FormatUint(user, 10)
}

func GetUnviKey() string {
	return "univ"
}

func GetGroupKey(group string) string {
	return "group:" + group
}

func GetUserGroupKey(uID uint64) string {
	return "groups:" + strconv.FormatUint(uID, 10)
}

func GetPostCmtKey(uID uint64, pID uint64) string {
	return "cmt:" + strconv.FormatUint(uID, 10) + ":" + strconv.FormatUint(pID, 10)
}

func GetPostLikeKey(uID uint64, pID uint64) string {
	return "plike:" + strconv.FormatUint(uID, 10) + ":" + strconv.FormatUint(pID, 10)
}

func GetUserLikeKey(uID uint64) string {
	return "ulike:" + strconv.FormatUint(uID, 10)
}

func GetLikeUserKey(uID uint64) string {
	return "likeu:" + strconv.FormatUint(uID, 10)
}
