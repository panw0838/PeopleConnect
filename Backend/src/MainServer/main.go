package main

import (
	"fmt"
	"log"
	"message"
	"net/http"
	"post"
	"strings"
	"user"
)

const crtPath = "C:/Users/panwang/PeopleConnect/Backend/src/server.crt"
const keyPath = "C:/Users/panwang/PeopleConnect/Backend/src/server.key"

type SyncInput struct {
	Mess uint32 `json:"messID"`
	Post uint32 `json:"postID"`
}

type SyncReturn struct {
	From uint64 `json:"from"`
	To   uint64 `json:"to"`
	Mess string `json:"mess"`
}

func syncHandler(w http.ResponseWriter, r *http.Request) {
	p := strings.TrimPrefix(r.URL.Path, "/files/")
	fmt.Println(p)
}

func main() {
	user.InitRelationCash()

	http.HandleFunc("/sync", syncHandler)

	http.HandleFunc("/login", user.LoginHandler)
	http.HandleFunc("/registry", user.RegisterHandler)

	http.HandleFunc("/addtag", user.AddTagHandler)
	http.HandleFunc("/remtag", user.RemTagHandler)

	http.HandleFunc("/users", user.GetUsersHandler)
	http.HandleFunc("/contacts", user.GetContactsHandler)
	http.HandleFunc("/nearusers", user.GetNearUsersHandler)
	http.HandleFunc("/possiblecontacts", user.GetPossibleContactsHandler)
	http.HandleFunc("/photos", user.GetPhotosHandler)
	http.HandleFunc("/searchcontact", user.SearchContactHandler)
	http.HandleFunc("/addcontact", user.AddContactHandler)
	http.HandleFunc("/remcontact", user.RemContactHandler)
	http.HandleFunc("/updatetagmember", user.UpdateTagMemberHandler)

	http.HandleFunc("/syncmessege", message.SyncMessegeHandler)
	http.HandleFunc("/requestcontact", message.RequestContactHandler)
	http.HandleFunc("/syncrequests", message.SyncRequestsHandler)
	http.HandleFunc("/sendmessege", message.SendMsgHandler)

	http.HandleFunc("/newpost", post.NewPostHandler)
	http.HandleFunc("/delpost", post.DelPostHandler)
	http.HandleFunc("/syncposts", post.SyncPostsHandler)
	http.HandleFunc("/synccontactposts", post.SyncContactPostsHandler)
	http.HandleFunc("/syncnearbyposts", post.SyncNearbyPostsHandler)
	http.HandleFunc("/previews", post.GetPreviewsHandler)
	http.HandleFunc("/comment", post.NewCommentHandler)
	http.HandleFunc("/delcmt", post.DelCmtHandler)
	http.HandleFunc("/updatecmts", post.UpdateCommentsHandler)

	fs := http.FileServer(http.Dir("files"))
	http.Handle("/files/", http.StripPrefix("/files/", fs))

	e := http.ListenAndServeTLS(":8080", crtPath, keyPath, nil)
	if e != nil {
		log.Fatal("ListenAndServe: ", e)
	}
}
