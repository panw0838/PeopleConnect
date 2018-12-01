package main

/*
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

	// notify user2 to receive messege
	cashed, userCash := cash.GetAccountCash(input.To)
	if cashed {
		sync := []byte{Messege_Syc, 0} // messege id
		n, err := userCash.Conn.Write(sync)
		if err == nil && n > 0 {
			fmt.Println("messege: notified")
		}
	}
	err = dbAddMessege(input, c)
	if err != nil {
		return
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
*/
