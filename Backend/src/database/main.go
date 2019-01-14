package main

import (
	"share"

	"github.com/garyburd/redigo/redis"
	"github.com/tealeg/xlsx"
)

func addUniv(name string, c redis.Conn) error {
	unvKey := share.GetUnviKey()
	_, err := c.Do("SADD", unvKey, name)
	return err
}

const xlsPath = "C:/Users/panwang/PeopleConnect/Backend/china_univ_1.xlsx"

func initUnivs() error {
	xlFile, err := xlsx.OpenFile(xlsPath)
	if err != nil {
		panic(err)
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		return err
	}
	defer c.Close()

	var first = true
	for _, row := range xlFile.Sheets[0].Rows {
		println(row.Cells[1].String())
		name := row.Cells[1].String()
		if len(name) > 0 && !first {
			addUniv(name, c)
		}
		first = false
	}

	return nil
}

func main() {
	err := initUnivs()
	println(err)
}
