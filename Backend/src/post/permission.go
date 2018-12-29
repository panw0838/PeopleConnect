package post

import (
	"share"
	"user"

	"github.com/garyburd/redigo/redis"
)

const SelfGroup uint32 = 0
const FriendGroup uint32 = 1
const StrangerGroup uint32 = 2

func PostForFriend(uFlag uint64, pFlag uint64) bool {
	return ((uFlag & pFlag & user.FriendMask) != 0)
}

func friendPost(uID uint64, oID uint64, pFlag uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != oID {
		oFlag, _, err := user.GetCashFlag(oID, uID, c)
		if err != nil {
			return false, err
		}
		canSee = PostForFriend(oFlag, pFlag)
	}

	return canSee, nil
}

func friendComment(uID uint64, from uint64, to uint64, c redis.Conn) (bool, error) {
	if uID == from || uID == to {
		return true, nil
	}

	canSee, err := user.IsFriend(from, uID, c)
	if err != nil {
		return false, err
	}

	if canSee && to != 0 {
		canSee, err = user.IsFriend(to, uID, c)
		if err != nil {
			return false, err
		}
	}

	return canSee, nil
}

func strangerComment(uID uint64, from uint64, to uint64, c redis.Conn) (bool, error) {
	if uID == from || uID == to {
		return true, nil
	}

	canSee, err := user.IsStranger(from, uID, c)
	if err != nil {
		return false, err
	}

	if canSee && to != 0 {
		canSee, err = user.IsStranger(to, uID, c)
		if err != nil {
			return false, err
		}
	}

	return canSee, nil
}

func groupComment(uID uint64, gID uint32, from uint64, to uint64, c redis.Conn) (bool, error) {
	if uID == from || uID == to {
		return true, nil
	}

	groupKey := share.GetGroupKey(gID)

	fromMember, err := redis.Int(c.Do("SISMEMBER", groupKey, from))
	if err != nil {
		return false, err
	}
	canSee := (fromMember == 1)
	if canSee {
		fromBlack, err := user.IsBlacklist(uID, from, c)
		if err != nil {
			return false, err
		}
		canSee = !fromBlack
	}

	if canSee && to != 0 {
		toMember, err := redis.Int(c.Do("SISMEMBER", groupKey, from))
		if err != nil {
			return false, err
		}
		canSee = (toMember == 1)
		if canSee {
			fromBlack, err := user.IsBlacklist(uID, from, c)
			if err != nil {
				return false, err
			}
			canSee = !fromBlack
		}
	}

	return canSee, nil
}

func canSeeComment(uID uint64, src uint32, from uint64, to uint64, c redis.Conn) (bool, error) {
	if src == SelfGroup {
		return true, nil
	} else if src == FriendGroup {
		// friends publish
		return friendComment(uID, from, to, c)
	} else if src == StrangerGroup {
		// stranger publish
		return strangerComment(uID, from, to, c)
	} else {
		// group publish
		return groupComment(uID, src, from, to, c)
	}
}
