package post

import (
	"fmt"
	"image"
	"image/png"
	"io/ioutil"
	"math"
	"os"
	"path/filepath"
	"strconv"

	"github.com/nfnt/resize"
)

const DEFAULT_MAX_WIDTH float64 = 320
const DEFAULT_MAX_HEIGHT float64 = 240

func getSnapPath(cID uint64, pID uint64, fileName string) string {
	uPath := strconv.FormatUint(cID, 10)
	pPath := strconv.FormatUint(pID, 10)
	return filepath.Join("files", uPath, pPath, "snap_"+fileName)
}

func getFilePath(cID uint64, pID uint64, fileName string) string {
	uPath := strconv.FormatUint(cID, 10)
	pPath := strconv.FormatUint(pID, 10)
	return filepath.Join("files", uPath, pPath, fileName)
}

// 计算图片缩放后的尺寸
func calculateRatioFit(srcWidth, srcHeight int) (int, int) {
	ratio := math.Min(DEFAULT_MAX_WIDTH/float64(srcWidth), DEFAULT_MAX_HEIGHT/float64(srcHeight))
	return int(math.Ceil(float64(srcWidth) * ratio)), int(math.Ceil(float64(srcHeight) * ratio))
}

func getSnapshot(cID uint64, pID uint64, fileName string) ([]byte, error) {
	snapPath := getSnapPath(cID, pID, fileName)
	if _, err := os.Stat(snapPath); os.IsNotExist(err) {
		filePath := getFilePath(cID, pID, fileName)
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			return nil, nil
		}
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
