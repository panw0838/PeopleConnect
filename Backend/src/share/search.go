package share

import (
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
	for _, ch := range []rune(key) {
		for {
			if pNode == nil {
				pNode = new(SearchNode)
				pNode.ch = ch
				pNode.pChild = nil
				pNode.pSid = nil
				pNode.str = ""
				pPre.pSid = pNode
			} else if pNode.ch != ch {
				pPre = pNode
				pNode = pNode.pSid
			} else {
				// found, go to next ch
				if pNode.pChild == nil {
					pNode.pChild = new(SearchNode)
					pNode.pChild.pSid = nil
					pNode.pChild.pChild = nil
					pNode.pChild.ch = ch
					pNode.pChild.str = ""
				}
				pPre = pNode
				pNode = pNode.pChild
				break
			}
		}
	}
	pNode.str = key
}

func printSearcTree(pNode *SearchNode) {
	if pNode == nil {
		return
	}
	printSearcTree(pNode.pChild)
	println(pNode.ch, pNode.pChild, pNode.pSid)
	printSearcTree(pNode.pSid)
}

func BuildSearchTree() {
	head.ch = 0
	head.pSid = nil
	head.pChild = nil

	c, err := redis.Dial("tcp", ContactDB)
	if err != nil {
		panic(err)
	}
	defer c.Close()

	univKey := GetUnviKey()
	names, err := redis.Strings(c.Do("ZRANGE", univKey, 0, -1))
	if err != nil {
		panic(err)
	}

	for _, name := range names {
		InsertKey(name)
	}

	// print tree
	printSearcTree(&head)
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
	for _, ch := range []rune(key) {
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
