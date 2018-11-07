package user

const BLACKLIST_BIT uint32 = 1
const FAMILY_BIT uint32 = 2
const CLASSMATE_BIT uint32 = 4
const COWORKER_BIT uint32 = 8
const FRIEND_BIT uint32 = 16

const MAX_USER_TAGS uint32 = 20
const SYSTEM_TAG_END uint32 = 5
const USER_TAG_START uint32 = 11

// system tags:
// 0 blacklist, 1 family, 2 classmate, 3 coworker, 4 friend
// 5 - 10 reserved, normal contact doesn't take bit
// self define start from 11 - 31, 20 tags in total

// father tag:
// 0, no father
// 1 - 11, system father
// 12 - 31 user define tag

type TagInfo struct {
	TagID    byte // self define tag
	FatherID byte // 0 no father, 1 blacklist, ... , 12 1st define tag
	TagName  string
}

func isSystemTag(tagID uint32) bool {
	return tagID >= 0 && tagID < SYSTEM_TAG_END
}

func isUserTag(tagID uint32) bool {
	return tagID >= USER_TAG_START && tagID < USER_TAG_START+MAX_USER_TAGS
}

func getTagBits(tagID uint32, fatherID uint32) uint32 {
	var bits uint32 = (1 << tagID)
	if fatherID != 0 {
		bits |= (1 << fatherID)
	}
	return bits
}
