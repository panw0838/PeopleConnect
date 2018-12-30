package post

import (
	"encoding/json"
	"net/http"
	"share"

	"github.com/garyburd/redigo/redis"
)

// source indicates where post come from
// it can be group id or friend posts or/and stranger posts
type AddCmtInput struct {
	UID       uint64 `json:"uid"`
	To        uint64 `json:"to"`
	PostOwner uint64 `json:"oid"`
	PostID    uint64 `json:"pid"`
	Msg       string `json:"cmt"`
	Group     uint32 `json:"src"`
}

type CommentResponse struct {
	CmtID uint64 `json:"cid"`
}

func NewCommentHandler(w http.ResponseWriter, r *http.Request) {
	var input AddCmtInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	cmtID, err := dbAddComment(input, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	var response CommentResponse
	response.CmtID = cmtID
	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type DelCmtInput struct {
	UID       uint64 `json:"uid"`
	CmtID     uint64 `json:"cid"`
	PostOwner uint64 `json:"oid"`
	PostID    uint64 `json:"pid"`
}

func DelCmtHandler(w http.ResponseWriter, r *http.Request) {
	var input DelCmtInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	err = dbDelComment(input, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
}

type UpdateCmtInfo struct {
	Owner uint64 `json:"owner"`
	Post  uint64 `json:"post"`
	Start uint64 `json:"start"`
}

type UpdateCmtReturn struct {
	Comments []Comment `json:"cmts"`
}

type UpdateCommentsInput struct {
	User     uint64          `json:"user"`
	Source   uint32          `json:"src"`
	Comments []UpdateCmtInfo `json:"cmts"`
}

type UpdateCommentsReturn struct {
	Returns []UpdateCmtReturn `json:"rets"`
}

func UpdateCommentsHandler(w http.ResponseWriter, r *http.Request) {
	var input UpdateCommentsInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	var response UpdateCommentsReturn

	for _, cmtInput := range input.Comments {
		comments, err := dbGetComments(cmtInput.Owner, cmtInput.Post, input.User, input.Source, cmtInput.Start, c)
		if err != nil {
			share.WriteError(w, 1)
			return
		}
		var cmtReturn UpdateCmtReturn
		cmtReturn.Comments = comments
		response.Returns = append(response.Returns, cmtReturn)
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type LikePostInput struct {
	UID  uint64 `json:"uid"`
	OID  uint64 `json:"oid"`
	PID  uint64 `json:"pid"`
	Like bool   `json:"like"`
}

func LikePostHandler(w http.ResponseWriter, r *http.Request) {
	var input LikePostInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	if input.UID == input.OID {
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	err = dbLikePost(input.UID, input.OID, input.PID, input.Like, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
}
