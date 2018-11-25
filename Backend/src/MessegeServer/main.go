package main

import (
	"fmt"
	"messege"
	"net"
)

func main() {
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
	buf := make([]byte, 1024)
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
		case messege.Log_Pkg:
			messege.HandleLogon(buf[2:n], conn)
			fmt.Println("log pkg")
			break
		case messege.Messege_Pkg:
			messege.HandleSendMessege(buf[2:n], conn)
			fmt.Println("messege pkg")
			break
		}
	}
}
