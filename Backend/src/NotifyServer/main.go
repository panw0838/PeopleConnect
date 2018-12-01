package main

import (
	"cashes"
	"encoding/json"
	"fmt"
	"net"
	"user"
)

const Connect_Ack byte = 0
const Log_Pkg byte = 1
const Log_Act byte = 2
const Notify_Pkg byte = 3
const Notify_Act byte = 4
const Notify_Syc byte = 5
const Messege_Pkg byte = 3
const Messege_Ack byte = 4
const Messege_Syc byte = 5

func HandleLogon(buf []byte, conn net.Conn) error {
	var input user.AccountInfo
	err := json.Unmarshal(buf[0:], &input)
	if err != nil {
		return err
	}

	cash.SetAccountCash(input.UserID, conn)

	feed := []byte{Log_Act, 0}
	conn.Write(feed)

	return nil
}

func HandleNotify(buf []byte, conn net.Conn) error {
	var input user.AccountInfo
	err := json.Unmarshal(buf[0:], &input)
	if err != nil {
		return err
	}
	// notify user2 to receive messege
	cashed, userCash := cash.GetAccountCash(input.UserID)
	if cashed {
		sync := []byte{Notify_Syc, 0} // messege id
		n, err := userCash.Conn.Write(sync)
		if err == nil && n > 0 {
			fmt.Println("messege: notified")
		}
	}
	return nil
}

func main() {
	cash.InitUserCash()
	//cash.InitRelationCash()
	lisener, err := net.Listen("tcp", ":8888")
	if err != nil {
		fmt.Println("listen err")
		return
	}

	for {
		conn, err := lisener.Accept()
		if err != nil {
			fmt.Println("accept error")
			continue
		}
		fmt.Printf("new connection %s\n", conn.RemoteAddr())
		go handleClient(conn)
	}
}

func handleClient(conn net.Conn) {
	defer conn.Close()
	buf := make([]byte, 100)
	for {
		n, err := conn.Read(buf)
		if err != nil || n == 0 {
			return
		}
		fmt.Printf("new pkg\n%s\n", buf)

		// package header
		handlerID := buf[0]
		//versionID := bytes[1]

		switch handlerID {
		case Log_Pkg:
			HandleLogon(buf[2:n], conn)
			fmt.Println("log pkg")
			break
		case Notify_Pkg:
			HandleNotify(buf[2:n], conn)
			fmt.Println("notify pkg")
			break
		}
	}
}
