package post

import (
	"user"

	"github.com/garyburd/redigo/redis"
)

const AllGroups uint32 = 0
const FriendPosts uint32 = 1
const NearPosts uint32 = 2
const GroupPosts uint32 = 3

func PostVisibleForFriend(uFlag uint64, pFlag uint64) bool {
	return ((uFlag & pFlag & user.FriendMask) != 0)
}

func canSeeFPost(uID uint64, oID uint64, pFlag uint64, c redis.Conn) (bool, error) {
	var canSee = true

	if uID != oID {
		oFlag, _, err := user.GetCashFlag(oID, uID, c)
		if err != nil {
			return false, err
		}
		canSee = PostVisibleForFriend(oFlag, pFlag)
	}

	return canSee, nil
}

func canSeeFCmt(uID uint64, cmt Comment, c redis.Conn) (bool, error) {
	if uID == cmt.From || uID == cmt.To {
		return true, nil
	}

	canSee, err := user.IsFriend(cmt.From, uID, c)
	if err != nil {
		return false, err
	}

	if canSee && cmt.To != 0 {
		canSee, err = user.IsFriend(cmt.To, uID, c)
		if err != nil {
			return false, err
		}
	}

	return canSee, nil
}

func canSeeNCmt(uID uint64, cmt Comment, c redis.Conn) (bool, error) {
	if uID == cmt.From || uID == cmt.To {
		return true, nil
	}

	canSee, err := user.IsStranger(cmt.From, uID, c)
	if err != nil {
		return false, err
	}

	if canSee && cmt.To != 0 {
		canSee, err = user.IsStranger(cmt.To, uID, c)
		if err != nil {
			return false, err
		}
	}

	return canSee, nil
}

func canSeeGCmt(uID uint64, cmt Comment, c redis.Conn) (bool, error) {
	if uID == cmt.From || uID == cmt.To {
		return true, nil
	}

	black, err := user.IsBlacklist(uID, cmt.From, c)
	if err != nil {
		return false, err
	}
	canSee := !black

	if canSee && cmt.To != 0 {
		black, err = user.IsBlacklist(uID, cmt.To, c)
		if err != nil {
			return false, err
		}
		canSee = !black
	}

	return canSee, nil
}

func canSeeComment(uID uint64, oID uint64, src uint32, cmt Comment, c redis.Conn) (bool, error) {
	if src == AllGroups || cmt.Group == AllGroups {
		return true, nil
	} else if src != cmt.Group {
		return false, nil
	} else {
		if src == FriendPosts {
			// friends publish
			return canSeeFCmt(uID, cmt, c)
		} else if src == NearPosts {
			// stranger publish
			return canSeeNCmt(uID, cmt, c)
		} else {
			// group publish
			return canSeeGCmt(uID, cmt, c)
		}
	}
}
