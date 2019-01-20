package setup

import (
	"share"
	"strings"

	"github.com/garyburd/redigo/redis"
	"github.com/tealeg/xlsx"
)

func addUniv(unvKey string, name string, channel int, c redis.Conn) error {
	_, err := c.Do("ZADD", unvKey, channel, name)
	return err
}

func InitUnivs() {
	xlFile, err := xlsx.OpenFile(share.MainPath + "china_univ_1.xlsx")
	if err != nil {
		panic(err)
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		panic(err)
	}
	defer c.Close()

	unvKey := share.GetUnviKey()
	numUnvs, err := redis.Int(c.Do("ZCARD", unvKey))
	if err != nil {
		panic(err)
	}

	var newChannel int = 10000 + numUnvs

	for _, row := range xlFile.Sheets[0].Rows {
		name := row.Cells[1].String()
		if len(name) == 0 || strings.Compare(name, "学校名称") == 0 {
			continue
		}
		val, err := c.Do("ZSCORE", unvKey, name)
		if err != nil {
			panic(err)
		}
		if val == nil {
			addUniv(unvKey, name, newChannel, c)
			newChannel++
		}
	}
}
