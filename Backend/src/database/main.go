package main

import (
	"share"

	"github.com/garyburd/redigo/redis"
	"github.com/tealeg/xlsx"
)

func getUniv(name string, c redis.Conn) (int64, error) {
	unvKey := share.GetUnviKey()

	value, err := c.Do("ZSCORE", unvKey, name)
	if err != nil {
		return 0, err
	}
	if value == nil {
		return 0, nil
	}

	uID, err := share.GetInt64(value, err)
	if err != nil {
		return 0, err
	}

	return uID, nil
}

func addUniv(name string, c redis.Conn) (int64, error) {
	unvKey := share.GetUnviKey()
	newID, err := redis.Int64(c.Do("INCR", share.NewUnivKey))
	if err != nil {
		return 0, err
	}

	_, err = c.Do("ZADD", unvKey, newID, name)
	if err != nil {
		return 0, err
	}

	return newID, nil
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

	for _, row := range xlFile.Sheets[0].Rows {
		println(row.Cells[1].String())
		name := row.Cells[1].String()
		if len(name) > 0 {
			uID, err := getUniv(name, c)
			if err != nil {
				panic(err)
			}
			if uID == 0 {
				addUniv(name, c)
			}
		}
	}

	return nil
}

func main() {
	err := initUnivs()
	println(err)
}
