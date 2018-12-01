package post

import (
	"encoding/binary"
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

const maxUploadSize = 20 * 1024 * 1024

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
		} else if strings.Compare(k, "desc") == 0 {
			param.Desc = v[0]
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
	User   uint64   `json:"user"`
	Flag   uint64   `json:"flag"`
	Desc   string   `json:"desc"`
	Groups []uint64 `json:"group,omitempty"`
}

type NewPostReturn struct {
	Post uint64 `json:"post"`
}

func NewPostHandler(w http.ResponseWriter, r *http.Request) {
	t := time.Now()
	err := r.ParseMultipartForm(maxUploadSize)
	if err != nil {
		fmt.Fprintf(w, "Error: file too big")
		return
	}

	var input NewPostInput
	err = getFormInput(r.MultipartForm, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: read input")
		return
	}
	fmt.Printf("input %d %d\n", input.User, input.Flag)

	pID := share.GetTimeID(t)
	files, err := getFormFile(input.User, pID, r.MultipartForm)
	if err != nil {
		fmt.Fprintf(w, "Error: process file %v", err)
		removePostFiles(input.User, pID)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		removePostFiles(input.User, pID)
		return
	}
	defer c.Close()

	var postData PostData
	postData.Desc = input.Desc
	postData.Flag = input.Flag
	postData.Files = files
	postData.Time = t.Format(time.RFC3339)
	postData.Post = pID
	err = dbAddPost(input.User, pID, postData, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		removePostFiles(input.User, pID)
		return
	}

	err = dbPublishPost(input.User, pID, input.Flag, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var response NewPostReturn
	response.Post = pID
	bytes, err := json.Marshal(response)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", bytes)
}

func DelPostHandler(w http.ResponseWriter, r *http.Request) {
}

type SyncPostInput struct {
	User uint64 `json:"user"`
	Post uint64 `json:"post"`
}

type SyncPostReturn struct {
	Posts []PostData `json:"posts"`
}

func SyncPostsHandler(w http.ResponseWriter, r *http.Request) {
	var input SyncPostInput
	err := share.ReadInput(r, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	posts, err := dbGetPublish(input.User, 0, 0xffffffffffffffff, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var response SyncPostReturn
	response.Posts = posts
	bytes, err := json.Marshal(response)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", bytes)
}

type GetPreviewsInput struct {
	Files []string `json:"files"`
}

func GetPreviewsHandler(w http.ResponseWriter, r *http.Request) {
	var input GetPreviewsInput
	var header = []byte{byte(0)}
	err := share.ReadInput(r, &input)
	if err != nil {
		header[0] = 1
		w.Write(header)
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
			header[0] = 2
			w.Write(header)
			return
		}

		len := len(data)
		lens = append(lens, len)
		datas = append(datas, data)
	}

	header = append(header, byte(len(lens)))
	w.Write(header)

	for _, len := range lens {
		var bufU32 = make([]byte, 4)
		binary.LittleEndian.PutUint32(bufU32, uint32(len))
		w.Write(bufU32)
	}

	for _, data := range datas {
		w.Write(data)
	}
}
