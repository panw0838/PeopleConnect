package cash

import (
	"fmt"
	"net"
	"sync"
)

type IPAddress struct {
	a [4]uint8
	p uint16
}

type UserCash struct {
	UID  uint64
	Flag uint64
	//Ip   IPAddress
	Conn net.Conn
	//Time time.Time
}

var mutex sync.Mutex
var UserCashSize uint32 = 0x8000000
var UserIndexSize uint64 = 0x10000000
var UserIndexMask uint64 = UserIndexSize - 1
var ActiveUsers []UserCash
var ActiveUsersIndex []uint32
var lastAvailble uint32 = 1

func getAccountCashIdx(uid uint64) uint32 {
	return ActiveUsersIndex[(uid & UserIndexMask)]
}

func forceGetAcctountCashIdx(uid uint64) uint32 {
	addr := (uid & UserIndexMask)
	if ActiveUsersIndex[addr] == 0 {
		mutex.Lock()
		ActiveUsersIndex[addr] = lastAvailble
		lastAvailble++
		mutex.Unlock()
	}
	return ActiveUsersIndex[addr]
}

func InitUserCash() {
	ActiveUsers = make([]UserCash, UserCashSize)
	ActiveUsersIndex = make([]uint32, UserIndexSize)
}

func UpdateAccountCash(uid uint64, conn net.Conn) {
	idx := forceGetAcctountCashIdx(uid)
	if idx != 0 {
		var activeUser UserCash
		activeUser.UID = uid
		//activeUser.Flag = flag
		//activeUser.Ip = getIPAddr(ip)
		activeUser.Conn = conn
		ActiveUsers[idx] = activeUser
	}
}

func SetAccountCash(uid uint64, conn net.Conn) {
	idx := forceGetAcctountCashIdx(uid)
	if idx < lastAvailble {
		var activeUser UserCash
		activeUser.UID = uid
		//activeUser.Flag = flag
		//activeUser.Ip = getIPAddr(ip)
		activeUser.Conn = conn
		ActiveUsers[idx] = activeUser
	}
	fmt.Printf("%x %s\n", idx, conn.RemoteAddr())
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
	fmt.Printf("%d %d\n", idx, uid)
	activeUser := ActiveUsers[idx]
	if activeUser.UID == uid {
		return true, activeUser
	} else {
		return false, activeUser
	}
}

func getIPAddr(addrStr string) IPAddress {
	var ipAddr IPAddress
	fmt.Sscanf(addrStr, "%d.%d.%d.%d:%d",
		&ipAddr.a[0], &ipAddr.a[1], &ipAddr.a[2], &ipAddr.a[3], &ipAddr.p)
	return ipAddr
}

func GetIPString(ip IPAddress) string {
	ipString := fmt.Sprintf("%d.%d.%d.%d:%d", ip.a[0], ip.a[1], ip.a[2], ip.a[3], ip.p)
	return ipString
}
