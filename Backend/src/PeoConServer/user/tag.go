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
// 6 - 9 reserved
const SYSTEM_TAG_END uint64 = 5

// user define tag id
// from 10 - 31, 22 tags in total
const USER_TAG_START uint64 = 10
const USER_TAG_END uint64 = 31
const MAX_USER_TAGS uint64 = 22

// father tag = tag id + 1
// 0, no father
// 1 - 6, system father
// 11 - 32 user define tag

type TagInfo struct {
	TagID    byte // self define tag
	FatherID byte // 0 no father, 1 blacklist, ... , 12 1st define tag
	TagName  string
}

func isSystemTag(tagID uint64) bool {
	return tagID >= 0 &&
		tagID <= SYSTEM_TAG_END
}

func isUserTag(tagID uint64) bool {
	return tagID >= USER_TAG_START &&
		tagID < USER_TAG_START+MAX_USER_TAGS
}

func getTagBits(tagID uint64, fatherID uint64) uint64 {
	var bits uint64 = (1 << tagID)
	if fatherID != 0 {
		bits |= (1 << (fatherID - ONE_64))
	}
	return bits
}
