package user

import (
	"crypto/sha1"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"mime"
	"mime/multipart"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"os"
	"path/filepath"
	"share"
	"strconv"
	"strings"
	"time"

	"github.com/garyburd/redigo/redis"
)

type AccountInfo struct {
	UserID uint64 `json:"user"`
}

type msgCodeInfo struct {
	Code int    `json:"code"`
	Msg  string `json:"msg"`
	Obj  string `json:"obj"`
}

type verifyCode struct {
	Code int `json:"code"`
}

var (
	msgurl     = "https://api.netease.im/sms/sendcode.action"
	verifyurl  = "https://api.netease.im/sms/verifycode.action"
	appKey     = "c327a886d3de7241e831881077d6579f"
	appSecret  = "c8461f27c6e1"
	nonce      = "yph2b"
	templateid = "9594093"
)

func genSHA1(sec, nonce, curtme string) string {
	var sum = sec + nonce + curtme
	h := sha1.New()
	h.Write([]byte(sum))
	bs := h.Sum(nil)
	sha := fmt.Sprintf("%x", bs)
	return sha
}

func checkCode(message []byte) (*msgCodeInfo, error) {
	var msg msgCodeInfo
	err := json.Unmarshal(message, &msg)
	if err != nil {
		return &msg, err
	}
	if msg.Code != 200 {
		return &msg, err
	}
	return &msg, nil
}

func SendCode(phone string) (*msgCodeInfo, error) {
	tr := &http.Transport{
		TLSClientConfig:    &tls.Config{InsecureSkipVerify: true},
		DisableCompression: true,
	}
	client := http.Client{Transport: tr}
	client.Jar, _ = cookiejar.New(nil)

	var mobile = url.Values{"mobile": {phone}, "templateid": {templateid}, "codeLen": {"6"}}

	req, err := http.NewRequest("POST", msgurl, strings.NewReader(mobile.Encode()))
	if err != nil {
		return nil, err
	}

	var curTime = strconv.Itoa(int(time.Now().Unix()))
	var checkSum = genSHA1(appSecret, nonce, curTime)

	req.Header.Add("AppKey", appKey)
	req.Header.Add("Nonce", nonce)
	req.Header.Add("CurTime", curTime)
	req.Header.Add("CheckSum", checkSum)
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	resp, err := client.Do(req) //发送
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close() //一定要关闭resp.Body
	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	msg, err := checkCode(data)
	if err != nil {
		return nil, err
	}
	return msg, nil
}

func VerifyCode(phone string, code string) (bool, error) {
	tr := &http.Transport{
		TLSClientConfig:    &tls.Config{InsecureSkipVerify: true},
		DisableCompression: true,
	}

	client := http.Client{Transport: tr}
	client.Jar, _ = cookiejar.New(nil)

	var mobile = url.Values{"mobile": {phone}, "code": {code}}

	req, err := http.NewRequest("POST", verifyurl, strings.NewReader(mobile.Encode()))
	if err != nil {
		return false, err
	}

	var curTime = strconv.Itoa(int(time.Now().Unix()))
	var checkSum = genSHA1(appSecret, nonce, curTime)

	req.Header.Add("AppKey", appKey)
	req.Header.Add("Nonce", nonce)
	req.Header.Add("CurTime", curTime)
	req.Header.Add("CheckSum", checkSum)
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	resp, err := client.Do(req) //发送
	if err != nil {
		return false, err
	}
	defer resp.Body.Close() //一定要关闭resp.Body
	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return false, err
	}
	var ret verifyCode
	err = json.Unmarshal(data, &ret)
	if err != nil {
		return false, err
	}
	if ret.Code == 200 {
		return true, nil
	} else {
		return false, nil
	}
}

func getMobile(code int, cell string) (string, error) {
	cellLen := len(cell)
	if code == 1 && cellLen != 10 || code == 86 && cellLen != 11 {
		return "", fmt.Errorf("Invalide cell %d %s", code, cell)
	}

	var mobile = cell
	if code != 86 {
		mobile = "+" + strconv.FormatInt(int64(code), 10) + "-" + mobile
	}
	return mobile, nil
}

type GetVCodeInput struct {
	Code int    `json:"code"`
	Cell string `json:"cell"`
}

func GetVerifyCodeHandler(w http.ResponseWriter, r *http.Request) {
	var input GetVCodeInput
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	mobile, err := getMobile(input.Code, input.Cell)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	_, err = SendCode(mobile)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteErrorCode(w, nil)
}

type RegistryInfo struct {
	CountryCode int    `json:"code"`
	CellNumber  string `json:"cell"`
	VerifyCode  string `json:"vcode"`
	UserName    string `json:"name"`
	Password    string `json:"pass"`
	Device      string `json:"device"`
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
		} else if strings.Compare(k, "name") == 0 {
			param.UserName = v[0]
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

			photoFolder := "photos"
			if _, err := os.Stat(photoFolder); os.IsNotExist(err) {
				err = os.MkdirAll(photoFolder, os.ModeDir)
				if err != nil {
					return err
				}
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
		share.WriteErrorCode(w, err)
		return
	}

	var input RegistryInfo
	err = getFormInput(r.MultipartForm, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	lenPass := len(input.Password)
	if lenPass < 8 || lenPass > 16 {
		share.WriteError(w, 4)
		return
	}

	mobile, err := getMobile(input.CountryCode, input.CellNumber)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	verified, err := VerifyCode(mobile, input.VerifyCode)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	if !verified {
		share.WriteErrorCode(w, fmt.Errorf("Reg verfiy code failed"))
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	defer c.Close()

	uID, err := dbRegistry(input, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	err = getPhoto(uID, r.MultipartForm)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var response AccountInfo
	response.UserID = uID
	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	share.WriteError(w, 0)
	w.Write(data)
}

type LoginInfo struct {
	CountryCode int    `json:"code"`
	CellNumber  string `json:"cell"`
	Password    string `json:"pass"`
	VerifyCode  string `json:"vcode"`
	Device      string `json:"device"`
}

type OutputTag struct {
	Father uint8  `json:"father"`
	Name   string `json:"name"`
	Index  uint8  `json:"id"`
}

type OutputGroup struct {
	ID   int64  `json:"id"`
	Name string `json:"name"`
}

type LoginResponse struct {
	UserID uint64      `json:"user"`
	Name   string      `json:"name"`
	Tags   []OutputTag `json:"tags,omitempty"`
	Groups []UserGroup `json:"groups,omitempty"`
}

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	var input LoginInfo
	err := share.ReadInput(r, &input)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	mobile, err := getMobile(input.CountryCode, input.CellNumber)
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

	uID, err := dbGetUser(input.CountryCode, input.CellNumber, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	if uID == 0 {
		share.WriteErrorCode(w, fmt.Errorf("Account not exists"))
		return
	}

	accountKey := GetAccountKey(uID)

	if len(input.Password) > 0 {
		pass, err := DbGetUserInfoField(accountKey, PassField, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}

		if strings.Compare(pass, input.Password) != 0 {
			share.WriteErrorCode(w, fmt.Errorf("Log, pass failed %d %s", uID, pass))
			return
		}
	} else {
		verified, err := VerifyCode(mobile, input.VerifyCode)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		if !verified {
			share.WriteErrorCode(w, fmt.Errorf("Log verfiy code failed"))
			return
		}
	}

	DbSetUserInfoField(accountKey, DeviceField, input.Device, c)

	name, err := DbGetUserInfoField(accountKey, NameField, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	tags, err := dbGetUserTags(uID, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	var response LoginResponse
	response.UserID = uID
	response.Name = name

	for idx, tag := range tags.Tags {
		if tag.Father != 0 {
			var newTag OutputTag
			newTag.Father = tag.Father
			newTag.Name = tag.Name
			newTag.Index = uint8(idx)
			response.Tags = append(response.Tags, newTag)
		}
	}

	groups, err := DbGetUserGroups(uID, c)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}
	for _, group := range groups {
		var groupInfo UserGroup
		groupInfo.Name = group
		groupInfo.ID, err = share.GetChannel(group, c)
		if err != nil {
			share.WriteErrorCode(w, err)
			return
		}
		response.Groups = append(response.Groups, groupInfo)
	}

	data, err := json.Marshal(&response)
	if err != nil {
		share.WriteErrorCode(w, err)
		return
	}

	fmt.Printf("%d %s\n", uID, r.RemoteAddr)
	share.WriteError(w, 0)
	w.Write(data)
}
