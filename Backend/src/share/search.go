package share

import (
	"fmt"
	"unicode/utf8"

	"github.com/garyburd/redigo/redis"
)

var head SearchNode

type SearchNode struct {
	ch     rune
	str    string
	pChild *SearchNode
	pSid   *SearchNode
}

func InsertKey(key string) {
	var pPre *SearchNode = nil
	var pNode *SearchNode = &head
	for _, ch := range key {
		if pNode == nil {
			pPre.pChild = new(SearchNode)
			pPre.pChild.pSid = nil
			pPre.pChild.pChild = nil
			pPre.pChild.ch = ch
			pPre.pChild.str = ""
			pPre = pPre.pChild
			pNode = pPre.pChild
		} else {
			for {
				if pNode == nil {
					pNode = new(SearchNode)
					pNode.ch = ch
					pNode.pChild = nil
					pNode.pSid = nil
					pNode.str = ""
					pPre.pSid = pNode
					pPre = pNode
					pNode = pNode.pChild
					break
				} else if pNode.ch != ch {
					pPre = pNode
					pNode = pNode.pSid
				} else {
					// found, go to next ch
					pPre = pNode
					pNode = pNode.pChild
					break
				}
			}
		}
	}
	println(key, utf8.RuneCountInString(key))
	pPre.str = key
}

func printSearcTree(pNode *SearchNode) {
	if pNode == nil {
		return
	}
	fmt.Printf("%c ", pNode.ch)
	printSearcTree(pNode.pChild)
	printSearcTree(pNode.pSid)
}

func BuildSearchTree() {
	head.ch = -1
	head.pSid = nil
	head.pChild = nil

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		panic(err)
	}
	defer c.Close()

	univKey := GetUnviKey()
	names, err := redis.Strings(c.Do("SMEMBERS", univKey))
	if err != nil {
		panic(err)
	}

	for _, name := range names {
		InsertKey(name)
	}

	// print tree
	//printSearcTree(head.pSid)
}

func getResult(pNode *SearchNode) []string {
	if pNode == nil {
		return nil
	}
	var results []string
	if len(pNode.str) > 0 {
		results = append(results, pNode.str)
	}
	lResults := getResult(pNode.pChild)
	for _, result := range lResults {
		results = append(results, result)
	}
	rResults := getResult(pNode.pSid)
	for _, result := range rResults {
		results = append(results, result)
	}
	return results
}

func Search(key string) []string {
	var pPre *SearchNode = nil
	var pNode *SearchNode = &head
	for _, ch := range key {
		for {
			if pNode == nil {
				return nil
			} else if pNode.ch != ch {
				pNode = pNode.pSid
			} else {
				pPre = pNode
				pNode = pNode.pChild
				break
			}
		}
	}
	var results []string
	if len(pPre.str) > 0 {
		results = append(results, pPre.str)
	}
	subResults := getResult(pNode)
	for _, result := range subResults {
		results = append(results, result)
	}

	return results
}
