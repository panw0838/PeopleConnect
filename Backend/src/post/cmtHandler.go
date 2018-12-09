package post

import (
	"encoding/json"
	"net/http"
	"share"

	"github.com/garyburd/redigo/redis"
)

type AddCmtInput struct {
	UID       uint64 `json:"uid"`
	To        uint64 `json:"to"`
	PubLvl    uint8  `json:"pub"`
	PostOwner uint64 `json:"oid"`
	PostID    uint64 `json:"pid"`
	LastCmt   uint64 `json:"last"`
	Msg       string `json:"cmt"`
}

type CommentResponse struct {
	CmtID    uint64    `json:"cid"`
	Comments []Comment `json:"cmts"`
}

func NewCommentHandler(w http.ResponseWriter, r *http.Request) {
	var input AddCmtInput
	var header = []byte{byte(0)}
	err := share.ReadInput(r, &input)
	if err != nil {
		header[0] = 1
		w.Write(header)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		header[0] = 2
		w.Write(header)
		return
	}
	defer c.Close()

	cmtID, comments, err := dbAddComment(input, c)
	if err != nil {
		header[0] = 3
		w.Write(header)
		return
	}

	var response CommentResponse
	response.CmtID = cmtID
	response.Comments = comments
	bytes, err := json.Marshal(response)
	if err != nil {
		header[0] = 4
		w.Write(header)
		return
	}

	w.Write(header)
	w.Write(bytes)
}

type DelCmtInput struct {
	UID       uint64 `json:"uid"`
	CmtID     uint64 `json:"cid"`
	PubLvl    uint8  `json:"pub"`
	PostOwner uint64 `json:"oid"`
	PostID    uint64 `json:"pid"`
	LastCmt   uint64 `json:"last"`
}

type DelCmtResponse struct {
	Comments []Comment `json:"cmts"`
}

func DelCmtHandler(w http.ResponseWriter, r *http.Request) {
	var input DelCmtInput
	var header = []byte{byte(0)}
	err := share.ReadInput(r, &input)
	if err != nil {
		header[0] = 1
		w.Write(header)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		header[0] = 2
		w.Write(header)
		return
	}
	defer c.Close()

	comments, err := dbDelComment(input, c)
	if err != nil {
		header[0] = 2
		w.Write(header)
		return
	}

	var response CommentResponse
	response.Comments = comments
	bytes, err := json.Marshal(response)
	if err != nil {
		header[0] = 4
		w.Write(header)
		return
	}

	w.Write(header)
	w.Write(bytes)
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
	PubLvl   uint8           `json:"pub"`
	Comments []UpdateCmtInfo `json:"cmts"`
}

type UpdateCommentsReturn struct {
	Returns []UpdateCmtReturn `json:"rets"`
}

func UpdateCommentsHandler(w http.ResponseWriter, r *http.Request) {
	var input UpdateCommentsInput
	var header = []byte{byte(0)}
	err := share.ReadInput(r, &input)
	if err != nil {
		header[0] = 1
		w.Write(header)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		header[0] = 2
		w.Write(header)
		return
	}
	defer c.Close()

	var response UpdateCommentsReturn

	for _, cmtInput := range input.Comments {
		cmtKey := getCommentKey(cmtInput.Owner, cmtInput.Post)
		comments, err := dbGetComments(cmtKey, input.PubLvl, input.User, cmtInput.Start, c)
		if err != nil {
			header[0] = 3
			w.Write(header)
			return
		}
		var cmtReturn UpdateCmtReturn
		cmtReturn.Comments = comments
		response.Returns = append(response.Returns, cmtReturn)
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		header[0] = 4
		w.Write(header)
		return
	}

	w.Write(header)
	w.Write(bytes)
}
