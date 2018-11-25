package messege

import (
	"encoding/json"
	"net"
	"share"
	"time"
	"user"
)

const Connect_Ack byte = 0
const Log_Pkg byte = 1
const Log_Act byte = 2
const Messege_Pkg byte = 3
const Messege_Ack byte = 4
const Messege_Fwd byte = 5

func HandleLogon(buf []byte, conn net.Conn) error {
	var input user.AccountInfo
	err := json.Unmarshal(buf[0:], &input)
	if err != nil {
		return err
	}

	share.SetAccountCash(input.UserID, conn)

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

	//c, err := redis.Dial("tcp", share.ContactDB)
	//if err != nil {
	//	return
	//}
	//defer c.Close()

	//relation, err := user.GetRelation(input.From, input.To, c)
	//if err != nil {
	//	return
	//}
	//if !user.IsFriend(relation) {
	//	return
	//}

	// TODO, notify user2 to receive messege
	notified := false
	cashed, userCash := share.GetAccountCash(input.To)
	if cashed {
		var messege Messege
		messege.From = input.From
		messege.Time = time.Now().Format(time.RFC3339)
		messege.Content = input.Mess

		messegeData, err := json.Marshal(&messege)
		if err != nil {
			return
		}

		data := append([]byte{Messege_Fwd, 0}, messegeData...)
		n, err := userCash.Conn.Write(data)
		if err == nil && n > 0 {
			notified = true
		}
	}
	if !notified {
		//err = dbAppendMessege(input, c)
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
