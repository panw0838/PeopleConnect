package post

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"mime"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"share"
	"strconv"
	"strings"
	"time"

	"github.com/garyburd/redigo/redis"
)

func getAttachmentName(userID uint64, postID uint32, idx int) string {
	return strconv.FormatUint(userID, 10) + "_" +
		strconv.FormatUint(uint64(postID), 10) + "_" +
		strconv.FormatUint(uint64(idx), 10)
}

func getFormInput(form *multipart.Form, param *NewPostInput) error {
	for k, v := range form.Value {
		if strings.Compare(k, "user") == 0 {
			value, err := strconv.Atoi(v[0])
			if err != nil {
				return err
			}
			param.User = uint64(value)
		} else if strings.Compare(k, "flag") == 0 {
			value, err := strconv.Atoi(v[0])
			if err != nil {
				return err
			}
			param.Flag = uint64(value)
		} else if strings.Compare(k, "cont") == 0 {
			param.Content = v[0]
		} else if strings.Compare(k, "X") == 0 {
			value, err := strconv.ParseFloat(v[0], 10)
			if err != nil {
				return err
			}
			param.X = value
		} else if strings.Compare(k, "Y") == 0 {
			value, err := strconv.ParseFloat(v[0], 10)
			if err != nil {
				return err
			}
			param.Y = value
		} else if strings.Compare(k, "near") == 0 {
			value, err := strconv.ParseBool(v[0])
			if err != nil {
				return err
			}
			param.Nearby = value
		} else if strings.Compare(k, "groups[]") == 0 {
			for _, value := range v {
				param.Groups = append(param.Groups, value)
			}
		}
	}

	return nil
}

func getFormFile(uID uint64, pID uint64, form *multipart.Form) ([]string, error) {
	//获取 multi-part/form中的文件数据
	var idx = 0
	uPath := strconv.FormatUint(uID, 10)
	pPath := strconv.FormatUint(pID, 10)
	folderPath := filepath.Join("files", uPath, pPath)
	var firstFile = true
	var files []string
	for _, v := range form.File {
		for i := 0; i < len(v); i++ {
			fmt.Println("fileName   :", v[i].Filename)
			fmt.Println("part-header:", v[i].Header)
			f, err := v[i].Open()
			if err != nil {
				return nil, err
			}
			fileData, err := ioutil.ReadAll(f)
			if err != nil {
				return nil, err
			}

			fileType := http.DetectContentType(fileData)
			if fileType != "image/jpeg" && fileType != "image/jpg" &&
				fileType != "image/gif" && fileType != "image/png" {
				return nil, fmt.Errorf("invalid file type")
			}

			fileEndings, err := mime.ExtensionsByType(fileType)
			if err != nil {
				return nil, err
			}

			if firstFile {
				err = os.MkdirAll(folderPath, os.ModeDir)
				if err != nil {
					return nil, err
				}
				firstFile = false
			}

			fileName := strconv.FormatUint(uint64(idx), 10) + fileEndings[0]
			newPath := filepath.Join("files", uPath, pPath, fileName)
			fmt.Printf("FileType: %s, Path: %s\n", fileType, newPath)
			files = append(files, fileName)

			newFile, err := os.Create(newPath)
			if err != nil {
				return nil, err
			}
			defer newFile.Close()
			if _, err := newFile.Write(fileData); err != nil {
				return nil, err
			}
		}
		idx++
	}
	return files, nil
}

func removePostFiles(uID uint64, pID uint64) {
	uPath := strconv.FormatUint(uID, 10)
	pPath := strconv.FormatUint(pID, 10)
	folderPath := filepath.Join("files", uPath, pPath)
	os.Remove(folderPath)
}

type NewPostInput struct {
	User    uint64   `json:"user"`
	Flag    uint64   `json:"flag"`
	Content string   `json:"cont"`
	X       float64  `json:"X"`
	Y       float64  `json:"Y"`
	Nearby  bool     `json:"near"`
	Groups  []string `json:"groups"`
}

type NewPostReturn struct {
	Post uint64 `json:"post"`
}

func NewPostHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseMultipartForm(share.MaxUploadSize)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var input NewPostInput
	err = getFormInput(r.MultipartForm, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	fmt.Printf("input %d %d\n", input.User, input.Flag)

	pID := share.GetTimeID(time.Now())
	files, err := getFormFile(input.User, pID, r.MultipartForm)
	if err != nil {
		share.WriteErrorCode(w, err)
		removePostFiles(input.User, pID)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		removePostFiles(input.User, pID)
		return
	}
	defer c.Close()

	var postData PostData

	postData.Content = input.Content
	postData.Flag = input.Flag
	postData.X = input.X
	postData.Y = input.Y
	postData.Files = files
	postData.ID = pID
	postData.Groups = input.Groups
	postData.Nearby = input.Nearby

	err = dbAddPost(input.User, postData, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		removePostFiles(input.User, pID)
		return
	}

	postData.Owner = input.User
	err = dbPublishPost(input.User, postData, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var response NewPostReturn
	response.Post = pID
	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type DelPostInput struct {
	User uint64 `json:"uid"`
	Post uint64 `json:"pid"`
}

func DelPostHandler(w http.ResponseWriter, r *http.Request) {
	var input DelPostInput
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

	err = dbDelPost(input.User, input.Post, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
}

type SyncFriendsPostInput struct {
	User     uint64   `json:"user"`
	LastPost uint64   `json:"last"`
	OIDs     []uint64 `json:"oids,omitempty"`
	PIDs     []uint64 `json:"pids,omitempty"`
	CIDs     []uint64 `json:"cids,omitempty"`
}

type SyncPostReturn struct {
	Posts []PostData      `json:"posts"`
	Cmts  []UpdateComment `json:"cmts"`
}

func SyncFriendsPostsHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncFriendsPostInput
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

	var response SyncPostReturn

	response.Posts, err = dbGetFriendPublish(input.User, input.LastPost+1, share.MAX_TIME, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	if len(input.PIDs) > 0 {
		pubKey := getFPubKey(input.User)
		response.Cmts, err = dbUpdatePubCmts(input.User, pubKey, input.PIDs, input.OIDs, input.CIDs, FriendChannel, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type SyncContactPostsInput struct {
	User     uint64   `json:"uid"`
	Contact  uint64   `json:"cid"`
	LastPost uint64   `json:"last"`
	PIDs     []uint64 `json:"pids,omitempty"`
	CIDs     []uint64 `json:"cids,omitempty"`
}

func SyncContactPostsHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncContactPostsInput
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

	var response SyncPostReturn

	if input.User == input.Contact {
		response.Posts, err = dbGetSelfPosts(input.User, input.LastPost+1, share.MAX_TIME, c)
		if len(input.PIDs) > 0 {
			comments, err := dbUpdateSelfCmts(input.User, input.PIDs, input.CIDs, c)
			if err != nil {
				share.WriteErrorCode(w, err)
				return
			}
			if len(comments) > 0 {
				response.Cmts = comments
			}
		}
	} else {
		response.Posts, err = dbGetUserPosts(input.User, input.Contact, input.LastPost, share.MAX_TIME, c)
	}
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type SyncNearInfoInput struct {
	User uint64  `json:"uid"`
	X    float64 `json:"x"`
	Y    float64 `json:"y"`
}

type SyncNearInfoReturn struct {
	GIDs []uint64 `json:"gids"`
}

func SyncNearInfoHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncNearInfoInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var response SyncNearInfoReturn
	response.GIDs = share.GetGeoIDs(input.X, input.Y)
	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type SyncNearPostsInput struct {
	UID      uint64   `json:"uid"`
	GID      uint64   `json:"gid"`
	LastPost uint64   `json:"last"`
	OIDs     []uint64 `json:"oids,omitempty"`
	PIDs     []uint64 `json:"pids,omitempty"`
	CIDs     []uint64 `json:"cids,omitempty"`
}

func SyncNearPostsHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncNearPostsInput
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

	var response SyncPostReturn

	response.Posts, err = dbGetNearbyPublish(input.UID, input.GID, input.LastPost, share.MAX_TIME, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	if len(input.PIDs) > 0 {
		nearKey := getNearKey(input.GID)
		response.Cmts, err = dbUpdatePubCmts(input.UID, nearKey, input.PIDs, input.OIDs, input.CIDs, NearChannel, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type SyncGroupPublishInput struct {
	User     uint64   `json:"uid"`
	Group    string   `json:"group"`
	LastPost uint64   `json:"last"`
	OIDs     []uint64 `json:"oids,omitempty"`
	PIDs     []uint64 `json:"pids,omitempty"`
	CIDs     []uint64 `json:"cids,omitempty"`
}

func SyncGroupPublishHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncGroupPublishInput
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

	var response SyncPostReturn

	response.Posts, err = dbGetGroupPublish(input.User, input.Group, input.LastPost+1, share.MAX_TIME, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	if len(input.PIDs) > 0 {
		pubKey := getGPubKey(input.Group)
		channel := share.GetChannel(0, input.Group)
		response.Cmts, err = dbUpdatePubCmts(input.User, pubKey, input.PIDs, input.OIDs, input.CIDs, channel, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type GetPreviewsInput struct {
	Files []string `json:"files"`
}

func GetPreviewsHandler(w http.ResponseWriter, r *http.Request) {
	var input GetPreviewsInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var lens []int
	var datas [][]byte

	for _, file := range input.Files {
		var cID uint64
		var pID uint64
		var fName string
		fmt.Sscanf(file, "%d_%d_%s", &cID, &pID, &fName)
		data, err := getSnapshot(cID, pID, fName)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		len := len(data)
		lens = append(lens, len)

		if len != 0 {
			datas = append(datas, data)
		}
	}

	share.WriteError(w, 0)
	w.Write([]byte{byte(len(lens))})

	for _, len := range lens {
		share.WriteU32(w, uint32(len))
	}

	for _, data := range datas {
		w.Write(data)
	}
}
