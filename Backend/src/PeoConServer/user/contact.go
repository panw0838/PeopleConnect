package user

const NAME_SIZE uint32 = 20

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
