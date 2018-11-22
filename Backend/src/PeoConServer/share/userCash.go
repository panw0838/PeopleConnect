package share

import (
	"fmt"
	"sync"
)

type IPAddress struct {
	p [4]uint8
}

type UserCash struct {
	UID  uint64
	Flag uint64
	Ip   IPAddress
	//Time time.Time
}

var mutex sync.Mutex
var UserCashSize uint32 = 0x8000000
var UserIndexSize uint64 = 0x10000000
var UserIndexMask uint64 = UserIndexSize - 1
var ActiveUsers []UserCash = make([]UserCash, UserCashSize)
var ActiveUsersIndex []uint32 = make([]uint32, UserIndexSize)
var lastAvailble uint32 = 1

func getAccountCashIdx(uid uint64) uint32 {
	return ActiveUsersIndex[(uid&UserIndexMask)] - 1
}

func forceGetAcctountCashIdx(uid uint64) uint32 {
	addr := (uid & UserIndexMask)
	if ActiveUsersIndex[addr] == 0 {
		mutex.Lock()
		ActiveUsersIndex[addr] = lastAvailble
		lastAvailble++
		mutex.Unlock()
	}
	return ActiveUsersIndex[addr] - 1
}

func UpdateAccountCash(uid uint64, ip string, flag uint64) {
	idx := getAccountCashIdx(uid)
	if idx < lastAvailble {
		var activeUser UserCash
		activeUser.UID = uid
		activeUser.Flag = flag
		activeUser.Ip = getIPAddr(ip)
		//activeUser.Time = time.Now()
		ActiveUsers[idx] = activeUser
	}
}

func SetAccountCash(uid uint64, ip string, flag uint64) {
	idx := forceGetAcctountCashIdx(uid)
	if idx < lastAvailble {
		var activeUser UserCash
		activeUser.UID = uid
		activeUser.Flag = flag
		activeUser.Ip = getIPAddr(ip)
		//activeUser.Time = time.Now()
		ActiveUsers[idx] = activeUser
	}
	fmt.Printf("%x %s\n", idx, ip)
}

func ReturnAccountCash(uid uint64) {
	idx := getAccountCashIdx(uid)
	if idx < lastAvailble && ActiveUsers[idx].UID == uid {
		mutex.Lock()
		last := ActiveUsers[lastAvailble-1]
		ActiveUsers[idx] = last
		ActiveUsersIndex[(last.UID & UserIndexMask)] = idx
		ActiveUsersIndex[idx] = UserCashSize
		lastAvailble--
		mutex.Unlock()
	}
}

func GetAccountCash(uid uint64) (bool, UserCash) {
	idx := getAccountCashIdx(uid)
	activeUser := ActiveUsers[idx]
	if activeUser.UID == uid {
		return true, activeUser
	} else {
		return false, activeUser
	}
}

func getIPAddr(addrStr string) IPAddress {
	var ipAddr IPAddress
	fmt.Sscanf(addrStr, "%d.%d.%d.%d",
		&ipAddr.p[0], &ipAddr.p[1], &ipAddr.p[2], &ipAddr.p[3])
	return ipAddr
}

func GetIPString(ip IPAddress) string {
	ipString := fmt.Sprintf("%d,%d,%d,%d", ip.p[0], ip.p[1], ip.p[2], ip.p[3])
	return ipString
}
