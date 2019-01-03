package user

import (
	"share"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const FlagField = "flag"
const NameField = "name"
const MessField = "mess"

const NAME_SIZE uint32 = 20

type ContactInfo struct {
	User uint64 `json:"user"`
	Flag uint64 `json:"flag"`
	Name string `json:"name"`
}

func GetContactsKey(user uint64) string {
	return "contacts:" + strconv.FormatUint(user, 10)
}

func dbGetContacts(userID uint64, c redis.Conn) ([]ContactInfo, error) {
	var contacts []ContactInfo
	contactsKey := GetContactsKey(userID)
	numContacts, err := redis.Int(c.Do("SCARD", contactsKey))
	if err != nil {
		return nil, err
	}

	if numContacts > 0 {
		members, err := redis.Values(c.Do("SMEMBERS", contactsKey))
		if err != nil {
			return nil, err
		}

		for _, member := range members {
			contactID, err := share.GetUint64(member, err)
			if err != nil {
				return nil, err
			}
			relateKey := GetRelationKey(userID, contactID)
			values, err := redis.Values(c.Do("HMGET", relateKey, FlagField, NameField))
			flag, err := share.GetUint64(values[0], err)
			name, err := redis.String(values[1], err)
			if err != nil {
				return nil, err
			}

			var newContact ContactInfo
			newContact.User = contactID
			newContact.Flag = flag
			newContact.Name = name
			contacts = append(contacts, newContact)
		}
	}

	return contacts, nil
}
