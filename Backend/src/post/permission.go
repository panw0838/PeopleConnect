package post

import (
	"user"

	"github.com/garyburd/redigo/redis"
)

const PostFlag_Stranger uint64 = 0x80000000

const PubLvl_Self uint8 = 0
const PubLvl_Friend uint8 = 1
const PubLvl_Group uint8 = 2
const PubLvl_Stranger uint8 = 3

func PostForStranger(flag uint64) bool {
	return (flag & PostFlag_Stranger) != 0
}

func PostForFriend(flag uint64) bool {
	return (flag & user.RelationMask) != 0
}

func friendPostFlag(uFlag uint64, pFlag uint64) bool {
	return ((uFlag & pFlag & user.ContactMask) != 0)
}

func friendPost(uID uint64, oID uint64, pFlag uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != oID {
		oFlag, _, err := user.GetCashFlag(oID, uID, c)
		if err != nil {
			return false, err
		}
		canSee = friendPostFlag(oFlag, pFlag)
	}

	return canSee, nil
}

func strangerPost(uID uint64, oID uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != oID {
		isStranger, err := user.IsStranger(uID, oID, c)
		if err != nil {
			return false, err
		}
		return isStranger, nil
	}

	return canSee, nil
}

func publicPost(uID uint64, oID uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != oID {
		isBlacklist, err := user.IsBlacklist(uID, oID, c)
		if err != nil {
			return false, err
		}
		return !isBlacklist, nil
	}

	return canSee, nil
}

func canSeePost(pubLvl uint8, uID uint64, oID uint64, pFlag uint64, c redis.Conn) (bool, error) {
	if pubLvl == PubLvl_Friend {
		// friends publish
		return friendPost(uID, oID, pFlag, c)
	} else if pubLvl == PubLvl_Group {
		// group publish
		return publicPost(uID, oID, c)
	} else if pubLvl == PubLvl_Stranger {
		// stranger publish
		return strangerPost(uID, oID, c)
	}
	return false, nil
}

func friendComment(uID uint64, from uint64, to uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != from {
		isFriend, err := user.IsFriend(from, uID, c)
		if err != nil {
			return false, err
		}
		canSee = isFriend
	}

	if canSee && to != 0 && uID != to {
		isFriend, err := user.IsFriend(to, uID, c)
		if err != nil {
			return false, err
		}
		canSee = isFriend
	}

	return canSee, nil
}

func strangerComment(uID uint64, from uint64, to uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != from {
		isStranger, err := user.IsStranger(from, uID, c)
		if err != nil {
			return false, err
		}
		canSee = isStranger
	}

	if canSee && to != 0 && uID != to {
		isStranger, err := user.IsStranger(to, uID, c)
		if err != nil {
			return false, err
		}
		canSee = isStranger
	}

	return canSee, nil
}

func publicComment(uID uint64, from uint64, to uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != from {
		isBlack, err := user.IsBlacklist(from, uID, c)
		if err != nil {
			return false, err
		}
		canSee = !isBlack
	}

	if canSee && to != 0 && uID != to {
		isBlack, err := user.IsBlacklist(to, uID, c)
		if err != nil {
			return false, err
		}
		canSee = !isBlack
	}

	return canSee, nil
}

func canSeeComment(uID uint64, pubLvl uint8, from uint64, to uint64, c redis.Conn) (bool, error) {
	if pubLvl == PubLvl_Self {
		return true, nil
	} else if pubLvl == PubLvl_Friend {
		// friends publish
		return friendComment(uID, from, to, c)
	} else if pubLvl == PubLvl_Group {
		// group publish
		return publicComment(uID, from, to, c)
	} else if pubLvl == PubLvl_Stranger {
		// stranger publish
		return strangerComment(uID, from, to, c)
	}
	return false, nil
}
