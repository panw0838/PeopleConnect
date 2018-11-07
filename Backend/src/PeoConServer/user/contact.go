package user

const NAME_SIZE uint32 = 20

type ContactInfo struct {
	userID uint64
	flag   uint64
	name   [NAME_SIZE]byte
}

type ContactCache struct {
	user1 uint64
	user2 uint64
	flag1 uint64
	flag2 uint64
}

// ContactsRing size 32 -> 64 -> 128 -> ...
type ContactsRing struct {
	numContacts uint32
	maxContacts uint32
	nextRing    uint32
	contacts    []ContactCache
}
