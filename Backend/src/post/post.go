package post

import (
	"encoding/json"
	"fmt"
	"image"
	"image/png"
	"io/ioutil"
	"math"
	"os"
	"path/filepath"
	"strconv"
	"user"

	"github.com/garyburd/redigo/redis"
	"github.com/nfnt/resize"
)

type Snap struct {
	Width  uint32 `json:"w"`
	Height uint32 `json:"h"`
	Stride uint32 `json:"s"`
	Data   []byte `json:"d"`
}

type PostData struct {
	User  uint64   `json:"user,omitempty"`
	Post  uint64   `json:"post,omitempty"`
	Desc  string   `json:"desc"`
	Flag  uint64   `json:"flag"`
	Time  string   `json:"time"`
	Files []string `json:"file"`
	//Images []image.Image `json:"image,omitempty"`
}

func getPostKey(userID uint64) string {
	return "post:" + strconv.FormatUint(userID, 10)
}

func getPublishKey(uID uint64) string {
	return "fposts" + strconv.FormatUint(uID, 10)
}

func canSeePost(cFlag uint64, pFlag uint64) bool {
	return (cFlag & pFlag) != 0
}

func getFilePath(cID uint64, pID uint64, fileName string) string {
	uPath := strconv.FormatUint(cID, 10)
	pPath := strconv.FormatUint(pID, 10)
	return filepath.Join("files", uPath, pPath, fileName)
}

func getSnapPath(cID uint64, pID uint64, fileName string) string {
	uPath := strconv.FormatUint(cID, 10)
	pPath := strconv.FormatUint(pID, 10)
	return filepath.Join("files", uPath, pPath, "snap_"+fileName)
}

const DEFAULT_MAX_WIDTH float64 = 320
const DEFAULT_MAX_HEIGHT float64 = 240

// 计算图片缩放后的尺寸
func calculateRatioFit(srcWidth, srcHeight int) (int, int) {
	ratio := math.Min(DEFAULT_MAX_WIDTH/float64(srcWidth), DEFAULT_MAX_HEIGHT/float64(srcHeight))
	return int(math.Ceil(float64(srcWidth) * ratio)), int(math.Ceil(float64(srcHeight) * ratio))
}

func getSnapshot(cID uint64, pID uint64, fileName string) ([]byte, error) {
	snapPath := getSnapPath(cID, pID, fileName)
	if _, err := os.Stat(snapPath); os.IsNotExist(err) {
		file, err := os.Open(getFilePath(cID, pID, fileName))
		if err != nil {
			return nil, err
		}
		defer file.Close()

		img, _, err := image.Decode(file)
		if err != nil {
			return nil, err
		}

		b := img.Bounds()
		width := b.Max.X
		height := b.Max.Y

		w, h := calculateRatioFit(width, height)

		fmt.Println("width = ", width, " height = ", height)
		fmt.Println("w = ", w, " h = ", h)

		// 调用resize库进行图片缩放
		m := resize.Resize(uint(w), uint(h), img, resize.Lanczos3)

		// 需要保存的文件
		imgfile, _ := os.Create(snapPath)
		defer imgfile.Close()

		// 以PNG格式保存文件
		err = png.Encode(imgfile, m)
		if err != nil {
			return nil, err
		}
	}

	file, err := os.Open(snapPath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	data, err := ioutil.ReadAll(file)
	if err != nil {
		return nil, err
	}

	return data, nil
}

func dbAddPost(uID uint64, pID uint64, data PostData, c redis.Conn) error {
	bytes, err := json.Marshal(data)
	if err != nil {
		return err
	}

	postKey := getPostKey(uID)
	_, err = c.Do("ZADD", postKey, pID, string(bytes))
	if err != nil {
		return err
	}
	return nil
}

func dbPublishPost(uID uint64, pID uint64, pFlag uint64, c redis.Conn) error {
	contactsKey := user.GetContactsKey(uID)
	contacts, err := redis.Strings(c.Do("SMEMBERS", contactsKey))
	if err != nil {
		return err
	}

	for _, contact := range contacts {
		cID, err := strconv.ParseUint(contact, 10, 64)
		if err != nil {
			return err
		}
		fpostsKey := getPublishKey(cID)
		cFlag, err := user.DbGetFlag(cID, uID, c)
		if err != nil {
			return err
		}
		if canSeePost(cFlag, pFlag) {
			publishStr := fmt.Sprintf("%d:%d", uID, pID)
			_, err := c.Do("ZADD", fpostsKey, pID, publishStr)
			if err != nil {
				return err
			}
		}
	}

	return nil
}

/*
func dbGetContactPosts(uID uint64, cID uint64, from uint64, to uint64, c redis.Conn) ([]PostData, []uint64, error) {
	postsKey := getPostKey(uID)
	c.Do("ZRANGE", postsKey, from, to, "WITHSCORES")
}
*/

func dbGetPublish(uID uint64, from uint64, to uint64, c redis.Conn) ([]PostData, error) {
	var results []PostData
	publishKey := getPublishKey(uID)
	publishes, err := redis.Strings(c.Do("ZRANGEBYSCORE", publishKey, from, to))
	if err != nil {
		return results, err
	}

	for _, publish := range publishes {
		var cID uint64
		var pID uint64
		fmt.Sscanf(publish, "%d:%d", &cID, &pID)
		postKey := getPostKey(cID)
		values, err := redis.Values(c.Do("ZRANGEBYSCORE", postKey, pID, pID))
		for _, value := range values {
			postData, err := redis.Bytes(value, err)
			if err != nil {
				return results, err
			}
			var post PostData
			err = json.Unmarshal(postData, &post)
			if err != nil {
				return results, err
			}
			cFlag, err := user.DbGetFlag(cID, uID, c)
			if err != nil {
				return results, err
			}
			if canSeePost(cFlag, post.Flag) {
				post.User = cID
				post.Post = pID
				results = append(results, post)
			}
		}
	}

	return results, nil
}
