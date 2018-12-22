package user

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

	"github.com/garyburd/redigo/redis"
)

type AccountInfo struct {
	UserID uint64 `json:"user"`
}

type RegistryInfo struct {
	CountryCode int    `json:"code"`
	CellNumber  string `json:"cell"`
	Password    string `json:"pass,omitempty"`
	Device      string `json:"device"`
	IPAddress   string
}

func getFormInput(form *multipart.Form, param *RegistryInfo) error {
	for k, v := range form.Value {
		if strings.Compare(k, "code") == 0 {
			value, err := strconv.Atoi(v[0])
			if err != nil {
				return err
			}
			param.CountryCode = value
		} else if strings.Compare(k, "cell") == 0 {
			param.CellNumber = v[0]
		} else if strings.Compare(k, "pass") == 0 {
			param.Password = v[0]
		} else if strings.Compare(k, "device") == 0 {
			param.Device = v[0]
		}
	}

	return nil
}

func getPhoto(uID uint64, form *multipart.Form) error {
	//获取 multi-part/form中的文件数据
	for _, v := range form.File {
		for i := 0; i < len(v); i++ {
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
			if fileType != "image/jpeg" &&
				fileType != "image/jpg" &&
				fileType != "image/gif" &&
				fileType != "image/png" {
				return fmt.Errorf("invalid file type")
			}

			fileEndings, err := mime.ExtensionsByType(fileType)
			if err != nil {
				return err
			}

			fileName := strconv.FormatUint(uID, 10) + fileEndings[0]
			filePath := filepath.Join("photos", fileName)
			fmt.Printf("FileType: %s, Path: %s\n", fileType, filePath)

			newFile, err := os.Create(filePath)
			if err != nil {
				return err
			}
			defer newFile.Close()
			if _, err := newFile.Write(fileData); err != nil {
				return err
			}
		}
	}
	return nil
}

func RegisterHandler(w http.ResponseWriter, r *http.Request) {
	err := r.ParseMultipartForm(share.MaxUploadSize)
	if err != nil {
		fmt.Fprintf(w, "Error: file too big")
		return
	}

	var input RegistryInfo
	err = getFormInput(r.MultipartForm, &input)
	if err != nil {
		fmt.Fprintf(w, "Error: read input")
		return
	}

	if len(input.CellNumber) == 0 {
		fmt.Fprintf(w, "Error: invalid cell number")
		return
	}

	lenPass := len(input.Password)
	if lenPass < 8 || lenPass > 16 {
		fmt.Fprintf(w, "Error: invalid password")
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	uID, err := dbRegistry(input, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	err = getPhoto(uID, r.MultipartForm)
	if err != nil {
		fmt.Fprintf(w, "Error: process file %v", err)
		return
	}

	var response AccountInfo
	response.UserID = uID
	data, err := json.Marshal(&response)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Fprintf(w, "%s", data)
}

type LoginInfo struct {
	CellNumber string `json:"cell"`
	CellCode   string `json:"code,omitempty"`
	Password   string `json:"pass,omitempty"`
	Device     string `json:"device"`
	IPAddress  string
}

type LoginResponse struct {
	UserID uint64   `json:"user"`
	Name   string   `json:"name"`
	Groups []uint64 `json:"groups,omitempty"`
}

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	var loginInfo LoginInfo
	err := share.ReadInput(r, &loginInfo)
	if err != nil {
		fmt.Fprintf(w, "Error: json read error")
		return
	}
	loginInfo.IPAddress = r.RemoteAddr

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}
	defer c.Close()

	userID, err := dbLogon(loginInfo, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	accountKey := GetAccountKey(userID)
	name, err := DbGetUserInfoField(accountKey, NameField, c)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	var feedback LoginResponse
	feedback.UserID = userID
	feedback.Name = name

	data, err := json.Marshal(&feedback)
	if err != nil {
		fmt.Fprintf(w, "Error: %v", err)
		return
	}

	fmt.Printf("%d %s\n", userID, r.RemoteAddr)
	fmt.Fprintf(w, "%s", data)
}
