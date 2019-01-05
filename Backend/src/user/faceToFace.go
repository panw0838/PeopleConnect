package user

import (
	"encoding/json"
	"net/http"
	"share"

	"github.com/garyburd/redigo/redis"
)

func GetFace2FaceKey() string {
	return "face2face"
}

type RegFaceToFaceInput struct {
	UID uint64  `json:"uid"`
	X   float64 `json:"x"`
	Y   float64 `json:"y"`
}

type GetFaceToFaceReturn struct {
	Users []NearUser `json:"users"`
}

func RegFaceUsersHandler(w http.ResponseWriter, r *http.Request) {
	var input RegFaceToFaceInput
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

	geoIDs := share.GetGeoIDs(input.X, input.Y)
	face2FaceKey := GetFace2FaceKey()

	// update user geo info
	err = dbSetUserPosition(input.UID, input.X, input.Y, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	// add user to facetoface table
	_, err = c.Do("ZADD", face2FaceKey, geoIDs[0], input.UID)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteErrorCode(w, nil)
}

type GetFaceToFaceInput struct {
	UID uint64 `json:"uid"`
}

func GetFaceUsersHandler(w http.ResponseWriter, r *http.Request) {
	var input GetFaceToFaceInput
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

	x, y, err := dbGetUserPosition(input.UID, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	face2FaceKey := GetFace2FaceKey()

	gID, err := share.GetUint64(c.Do("ZSCORE", face2FaceKey, input.UID))
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var users []User
	values, err := redis.Int64s(c.Do("ZRANGEBYSCORE", face2FaceKey, gID, gID))
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	for _, value := range values {
		cID := uint64(value)
		if input.UID == cID {
			continue
		}

		isStranger, err := IsStranger(input.UID, cID, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		if !isStranger {
			continue
		}

		userX, userY, err := dbGetUserPosition(cID, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		xOffset := x - userX
		yOffset := y - userY
		geoRange := 0.00001
		if xOffset > geoRange || xOffset < -geoRange || yOffset > geoRange || yOffset < -geoRange {
			continue
		}

		var user User
		user.UID = cID
		user.Name, err = DbGetUserName(cID, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		users = append(users, user)
	}

	data, err := json.Marshal(&users)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteErrorCode(w, nil)
	w.Write(data)
}

func RemFaceUsersHandler(w http.ResponseWriter, r *http.Request) {
	var input GetFaceToFaceInput
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

	face2FaceKey := GetFace2FaceKey()

	_, err = c.Do("ZREM", face2FaceKey, input.UID)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteErrorCode(w, nil)
}
