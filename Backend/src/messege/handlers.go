package messege

import (
	cash "cashes"
	"encoding/json"
	"fmt"
	"net"
	"share"
	"user"

	"github.com/garyburd/redigo/redis"
)

const Connect_Ack byte = 0
const Log_Pkg byte = 1
const Log_Act byte = 2
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

type SendMessegeInput struct {
	ID   uint32 `json:"id"`
	From uint64 `json:"from"`
	To   uint64 `json:"to"`
	Mess string `json:"mess"`
}

type SendMessegeReturn struct {
	ID uint32 `json:"id"`
}

func HandleSendMessege(buf []byte, conn net.Conn) {
	var input SendMessegeInput
	err := json.Unmarshal(buf, &input)
	if err != nil {
		return
	}

	c, err := redis.Dial("tcp", share.ContactDB)
	if err != nil {
		return
	}
	defer c.Close()

	var less uint64
	var more uint64
	if input.From < input.To {
		less = input.From
		more = input.To
	} else if input.From > input.To {
		less = input.To
		more = input.From
	} else {
		return
	}
	relation, err := cash.GetRelation(less, more, c)
	if err != nil {
		return
	}
	if !cash.IsFriend(relation) {
		fmt.Println("messege: not friend")
		return
	}

	// TODO, notify user2 to receive messege
	notified := false
	cashed, userCash := cash.GetAccountCash(input.To)
	if cashed {
		sync := []byte{Messege_Syc, 0} // messege id
		n, err := userCash.Conn.Write(sync)
		if err == nil && n > 0 {
			fmt.Println("messege: notified")
			notified = true
		}
	}
	if !notified {
		err = dbAddOfflineMessege(input, c)
		fmt.Println("messege: add offline messege")
		if err != nil {
			return
		}
	}

	var response SendMessegeReturn
	response.ID = input.ID
	data, err := json.Marshal(&response)
	if err != nil {
		return
	}
	feed := append([]byte{Messege_Ack, 0}, data...)
	conn.Write(feed)
}
