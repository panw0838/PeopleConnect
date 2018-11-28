package post

import (
	"fmt"
	"io/ioutil"
	"mime"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

const maxUploadSize = 20 * 1024 * 1024

type NewPostInput struct {
	User uint64 `json:"user"`
	Flag uint64 `json:"flag"`
	Desc string `json:"desc"`
	//Last uint32 `json:"last"`
}

type NewPostReturn struct {
}

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

func getFormFile(input NewPostInput, form *multipart.Form) error {
	//获取 multi-part/form中的文件数据
	var idx = 0
	for _, v := range form.File {
		for i := 0; i < len(v); i++ {
			fmt.Println("file part ", i, "-->")
			fmt.Println("fileName   :", v[i].Filename)
			fmt.Println("part-header:", v[i].Header)
			f, err := v[i].Open()
			if err != nil {
				return err
			}
			fileData, err := ioutil.ReadAll(f)
			if err != nil {
				return err
			}

			fileType := http.DetectContentType(fileData)
			if fileType != "image/jpeg" && fileType != "image/jpg" &&
				fileType != "image/gif" && fileType != "image/png" {
				return fmt.Errorf("invalid file type")
			}

			fileName := getAttachmentName(input.User, 0, idx)
			fileEndings, err := mime.ExtensionsByType(fileType)
			if err != nil {
				return err
			}
			newPath := filepath.Join("files", fileName+fileEndings[0])
			fmt.Printf("FileType: %s, Path: %s\n", fileType, newPath)

			newFile, err := os.Create(newPath)
			if err != nil {
				return err
			}
			defer newFile.Close()
			if _, err := newFile.Write(fileData); err != nil {
				return err
			}
		}
		idx++
	}
	return nil
}

func NewPostHandler(w http.ResponseWriter, r *http.Request) {
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

	err = getFormFile(input, r.MultipartForm)
	if err != nil {
		fmt.Fprintf(w, "Error: process file %v", err)
		return
	}

	fmt.Fprintf(w, "Success")
}

func DelPostHandler(w http.ResponseWriter, r *http.Request) {
}

func SyncPostsHandler(w http.ResponseWriter, r *http.Request) {
}
