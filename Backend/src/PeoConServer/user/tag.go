package user

const BLK_BIT uint64 = 0x1
const CTC_BIT uint64 = 0x2
const FRD_BIT uint64 = 0x4
const CWK_BIT uint64 = 0x8
const CLM_BIT uint64 = 0x10
const FML_BIT uint64 = 0x20

const ONE_64 uint64 = 0x1
const ZERO_64 uint64 = 0x0

// system tags id
// blacklist, contact, friend, coworker, classmate, family
// 0          1        2       3         4          5
const SYSTEM_TAG_START uint64 = 0
const SYSTEM_TAG_END uint64 = 5

// user define tag id
// from 32 - 63, 32 tags in total
const USER_TAG_START uint64 = 32
const USER_TAG_END uint64 = 63
const MAX_USER_TAGS uint64 = 32

// father tag
// 0, no father, blacklist has no sub tag
// 1 - 5, system father
// 32 - 63 user define tag

type TagInfo struct {
	TagID    byte // self define tag
	FatherID byte // 0 no father, 1 blacklist, ... , 12 1st define tag
	TagName  string
}

func isSystemTag(tagID uint64) bool {
	return tagID >= SYSTEM_TAG_START &&
		tagID <= SYSTEM_TAG_END
}

func isUserTag(tagID uint64) bool {
	return tagID >= USER_TAG_START &&
		tagID <= USER_TAG_END
}

func getUserTagIdx(tagID uint64) uint64 {
	return tagID - USER_TAG_START
}
