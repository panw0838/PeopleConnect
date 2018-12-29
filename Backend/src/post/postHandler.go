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
	Groups  []uint32 `json:"group"`
}

type NewPostReturn struct {
	Post uint64 `json:"post"`
}

func NewPostHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseMultipartForm(share.MaxUploadSize)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	var input NewPostInput
	err = getFormInput(r.MultipartForm, &input)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	fmt.Printf("input %d %d\n", input.User, input.Flag)

	pID := share.GetTimeID(time.Now())
	files, err := getFormFile(input.User, pID, r.MultipartForm)
	if err != nil {
		share.WriteError(w, 1)
		removePostFiles(input.User, pID)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
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
		share.WriteError(w, 1)
		removePostFiles(input.User, pID)
		return
	}

	postData.Owner = input.User
	err = dbPublishPost(input.User, postData, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	var response NewPostReturn
	response.Post = pID
	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteError(w, 1)
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
		share.WriteError(w, 1)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteError(w, 1)
		return
	}
	defer c.Close()

	err = dbDelPost(input.User, input.Post, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
}

type SyncPostInput struct {
	User   uint64 `json:"user"`
	PostID uint64 `json:"post"`
}

type SyncPostReturn struct {
	Posts []PostData `json:"posts"`
}

func SyncPostsHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncPostInput
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

	var from uint64 = 0
	if input.PostID != 0 {
		from = input.PostID + 1
	}
	posts, err := dbGetFriendPublish(input.User, from, share.MAX_TIME, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	var response SyncPostReturn
	response.Posts = posts

	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type SyncContactPostsInput struct {
	User    uint64 `json:"uid"`
	Contact uint64 `json:"cid"`
}

func SyncContactPostsHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncContactPostsInput
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

	var response SyncPostReturn

	if input.User == input.Contact {
		response.Posts, err = dbGetSelfPosts(input.User, 0, share.MAX_TIME, c)
	} else {
		response.Posts, err = dbGetUserPosts(input.User, input.Contact, 0, share.MAX_TIME, c)
	}
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type SyncNearbyPostsInput struct {
	User uint64  `json:"user"`
	X    float64 `json:"x"`
	Y    float64 `json:"y"`
}

func SyncNearbyPostsHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncNearbyPostsInput
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

	var response SyncPostReturn

	response.Posts, err = dbGetNearbyPublish(input, 0, share.MAX_TIME, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	share.WriteError(w, 0)
	w.Write(bytes)
}

type SyncGroupPublishInput struct {
	User  uint64 `json:"uid"`
	Group uint32 `json:"gid"`
}

func SyncGroupPublishHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncGroupPublishInput
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

	var response SyncPostReturn

	response.Posts, err = dbGetGroupPublish(input.User, input.Group, 0, share.MAX_TIME, c)
	if err != nil {
		share.WriteError(w, 1)
		return
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		share.WriteError(w, 1)
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
		share.WriteError(w, 1)
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
			share.WriteError(w, 1)
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
