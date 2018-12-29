package user

const ONE_64 uint64 = 0x1
const ZERO_64 uint64 = 0x0

// system tab bits
const BLK_BIT uint64 = ONE_64 << 32
const UDF_BIT uint64 = ONE_64 << 33
const FML_BIT uint64 = ONE_64 << 34
const CLM_BIT uint64 = ONE_64 << 35
const CWK_BIT uint64 = ONE_64 << 36
const FRD_BIT uint64 = ONE_64 << 37

const SYSTEM_TAG_BITS uint64 = 0x3E00000000

const SYSTEM_TAG_START uint8 = 32
const SYSTEM_TAG_END uint8 = 37
const SYSTEM_TAG_VALID_START uint8 = 33

// user define tag id
// from 32 - 63, 32 tags in total
const USER_TAG_START uint8 = 0
const USER_TAG_END uint8 = 31
const MAX_USER_TAGS uint64 = 32
const USER_TAG_BITS uint64 = 0xFFFFFFFF

const FriendMask uint64 = (SYSTEM_TAG_BITS | USER_TAG_BITS)

type TagInfo struct {
	TagID    uint8  `json:"id"`
	FatherID uint8  `json:"father"`
	TagName  string `json:"name"`
}

func isSystemTag(tagID uint8) bool {
	return tagID >= SYSTEM_TAG_START &&
		tagID <= SYSTEM_TAG_END
}

func isValidMainTag(tagID uint8) bool {
	return tagID >= SYSTEM_TAG_VALID_START &&
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
