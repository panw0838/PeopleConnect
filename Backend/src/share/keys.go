package share

import (
	"hash/crc32"
	"strconv"
)

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

func GetChannel(channel uint32, group string) uint32 {
	// channel 0 - 2 used for system channel only
	if len(group) > 0 {
		return crc32.ChecksumIEEE([]byte(group))
	} else {
		return channel
	}
}
