// Copyrights 2018, Pan Wang, (unpublished)

#ifndef USER_INFO_H
#define USER_INFO_H

#define MAX_TAGS_GROUP  8
#define TAG_NAME_SIZE   18
#define USER_NAME_SIZE  18

enum GroupTypes {
    Group_Family,
    Group_Classmate,
    Group_Coworker,
    Group_Friend,
    Group_Normal,
    Group_Blacklist,

    Group_Reserved_0,
    Group_Reserved_1,
    Group_Reserved_2,
    Group_Reserved_3,

    MaxGroups,
    NumGroups = Group_Reserved_0
};

union ContactID {
    struct Field {
        uint64  tagIndex : 4;      // tags
        uint64  uid      : 64 - 4; // uid
    };
    uint64  value;
};

// ContactsBlock levels
// 8 contacts -> 16 -> 32 -> 64 -> 128 -> 256
struct ContactsBlock {
    uint32      nxtBlock;
    uint32      numContacts;
    uint32      maxCoutacts;
    uint32      blockSize;
    ContactID   contacts[1];
};

struct GroupInfo {
    uint32  contactsIndex;
    uint32  numOfTags;
    wchar_t tagNames[MAX_TAGS_GROUP][TAG_NAME_SIZE];
};

struct UserInfo {
    uint64      uid;
    char        cellNumber[15]; // cell number as account
    char        password[15];   // user password
    uint32      IMEI[15];       // last device id
    wchar_t     nickName[USER_NAME_SIZE];
    GroupInfo   groups[MaxGroups];
};

#endif