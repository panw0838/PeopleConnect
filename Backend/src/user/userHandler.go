package user

import (
	"encoding/json"
	"net/http"
	"share"

	"github.com/garyburd/redigo/redis"
)

type GetUserDetailInput struct {
	UID uint64 `json:"uid"`
	CID uint64 `json:"cid"`
}

type GetUserDetailReturn struct {
	Like bool `json:"like"`
}

func GetUserDetailHandler(w http.ResponseWriter, r *http.Request) {
	var input GetUserDetailInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	var response GetUserDetailReturn

	likeUKey := share.GetLikeUserKey(input.CID)
	like, err := redis.Int(c.Do("SISMEMBER", likeUKey, input.UID))
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	response.Like = (like == 1)

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)

}
