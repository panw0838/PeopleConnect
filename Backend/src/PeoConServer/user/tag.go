package user

// system tab bits
const BLK_BIT uint64 = ONE_64
const CTC_BIT uint64 = ONE_64 << 1
const FRD_BIT uint64 = ONE_64 << 2
const CWK_BIT uint64 = ONE_64 << 3
const CLM_BIT uint64 = ONE_64 << 4
const FML_BIT uint64 = ONE_64 << 5

// user control bits
const ADD_CONFIRM uint64 = ONE_64 << 30
const NO_SEARCH uint64 = ONE_64 << 31

const ONE_64 uint64 = 0x1
const ZERO_64 uint64 = 0x0

// system tags id
// blacklist, contact, friend, coworker, classmate, family
// 0          1        2       3         4          5
const SYSTEM_TAG_START uint8 = 0
const SYSTEM_TAG_END uint8 = 5

// user define tag id
// from 32 - 63, 32 tags in total
const USER_TAG_START uint8 = 32
const USER_TAG_END uint8 = 63
const MAX_USER_TAGS uint64 = 32

// father tag
// 0, no father, blacklist has no sub tag
// 1 - 5, system father
// 32 - 63 user define tag

type TagInfo struct {
	TagID    uint8  `json:"id"`
	FatherID uint8  `json:"father"`
	TagName  string `json:"name"`
}

func isSystemTag(tagID uint8) bool {
	return tagID >= SYSTEM_TAG_START &&
		tagID <= SYSTEM_TAG_END
}

func isUserTag(tagID uint8) bool {
	return tagID >= USER_TAG_START &&
		tagID <= USER_TAG_END
}

func getTagBit(tagID uint8) uint64 {
	return ONE_64 << tagID
}

func getUserTagIdx(tagID uint8) uint8 {
	return tagID - USER_TAG_START
}

func inBlacklist(flag uint64) bool {
	return (flag & BLK_BIT) != 0
}
