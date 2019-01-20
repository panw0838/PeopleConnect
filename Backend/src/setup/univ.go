package setup

import (
	"share"

	"github.com/garyburd/redigo/redis"
	"github.com/tealeg/xlsx"
)

func addUniv(unvKey string, name string, channel int, c redis.Conn) error {
	_, err := c.Do("ZADD", unvKey, channel, name)
	return err
}

const xlsPath = "$GOPATH/china_univ_1.xlsx"

func InitUnivs() {
	xlFile, err := xlsx.OpenFile(xlsPath)
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

	var first = true
	for _, row := range xlFile.Sheets[0].Rows {
		name := row.Cells[1].String()
		if len(name) == 0 || first {
			first = false
			continue
		}
		channel, err := share.GetChannel(name, c)
		if err != nil {
			panic(err)
		}
		if channel == 0 {
			addUniv(unvKey, name, newChannel, c)
			newChannel++
		}
	}
}
