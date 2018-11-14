package user

const NAME_SIZE uint32 = 20

type ContactInfo struct {
	User uint64 `json:"user"`
	Flag uint64 `json:"flag"`
	Name string `json:"name"`
}

type FullContactInfo struct {
	Contacts []ContactInfo `json:"contacts"`
	Tags     []TagInfo     `json:"tags"`
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
