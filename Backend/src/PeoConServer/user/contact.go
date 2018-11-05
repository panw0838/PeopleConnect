package user

const BLACKLIST_BIT uint16 = 1
const FAMILY_BIT uint16 = 2
const CLASSMATE_BIT uint16 = 4
const COWORKER_BIT uint16 = 8
const FRIEND_BIT uint16 = 16
const NORMAL_BIT uint16 = 32

const NAME_SIZE uint32 = 40

type ContactInfo struct {
	userID uint32
	flag   uint32
	name   [NAME_SIZE]byte
}

type ContactCache struct {
	user1 uint32
	user2 uint32
	flag1 uint32
	flag2 uint32
}

// ContactsRing size 32 -> 64 -> 128 -> ...
type ContactsRing struct {
	numContacts uint32
	maxContacts uint32
	nextRing    uint32
	contacts    []ContactCache
}
