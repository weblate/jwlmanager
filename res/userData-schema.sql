--
-- Text encoding used: UTF-8
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: android_metadata
CREATE TABLE android_metadata (
    locale TEXT
);


-- Table: BlockRange
CREATE TABLE BlockRange (
    BlockRangeId INTEGER NOT NULL
                         PRIMARY KEY,
    BlockType    INTEGER NOT NULL,
    Identifier   INTEGER NOT NULL,
    StartToken   INTEGER,
    EndToken     INTEGER,
    UserMarkId   INTEGER NOT NULL,
    CHECK (BlockType BETWEEN 1 AND 2),
    FOREIGN KEY (
        UserMarkId
    )
    REFERENCES UserMark (UserMarkId) 
);


-- Table: Bookmark
CREATE TABLE Bookmark (
    BookmarkId            INTEGER NOT NULL
                                  PRIMARY KEY,
    LocationId            INTEGER NOT NULL,
    PublicationLocationId INTEGER NOT NULL,
    Slot                  INTEGER NOT NULL,
    Title                 TEXT    NOT NULL,
    Snippet               TEXT,
    BlockType             INTEGER NOT NULL
                                  DEFAULT 0,
    BlockIdentifier       INTEGER,
    FOREIGN KEY (
        LocationId
    )
    REFERENCES Location (LocationId),
    FOREIGN KEY (
        PublicationLocationId
    )
    REFERENCES Location (LocationId),
    CONSTRAINT PublicationLocationId_Slot UNIQUE (
        PublicationLocationId,
        Slot
    ),
    CHECK ( (BlockType = 0 AND 
             BlockIdentifier IS NULL) OR 
            ( (BlockType BETWEEN 1 AND 2) AND 
              BlockIdentifier IS NOT NULL) ) 
);


-- Table: InputField
CREATE TABLE InputField (
    LocationId INTEGER NOT NULL,
    TextTag    TEXT    NOT NULL,
    Value      TEXT    NOT NULL,
    FOREIGN KEY (
        LocationId
    )
    REFERENCES Location (LocationId),
    CONSTRAINT LocationId_TextTag PRIMARY KEY (
        LocationId,
        TextTag
    )
);


-- Table: LastModified
CREATE TABLE LastModified (
    LastModified TEXT NOT NULL
                    DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now') ) 
);


-- Table: Location
CREATE TABLE Location (
    LocationId     INTEGER NOT NULL
                           PRIMARY KEY,
    BookNumber     INTEGER,
    ChapterNumber  INTEGER,
    DocumentId     INTEGER,
    Track          INTEGER,
    IssueTagNumber INTEGER NOT NULL
                           DEFAULT 0,
    KeySymbol      TEXT,
    MepsLanguage   INTEGER NOT NULL,
    Type           INTEGER NOT NULL,
    Title          TEXT,
    UNIQUE (
        BookNumber,
        ChapterNumber,
        KeySymbol,
        MepsLanguage,
        Type
    ),
    UNIQUE (
        KeySymbol,
        IssueTagNumber,
        MepsLanguage,
        DocumentId,
        Track,
        Type
    ),
    CHECK ( (Type IN (0, 1) AND 
             KeySymbol IS NOT NULL) OR 
            (Type = 0 AND 
             (DocumentId IS NOT NULL AND 
              DocumentId != 0) AND 
             BookNumber IS NULL AND 
             ChapterNumber IS NULL AND 
             Track IS NULL) OR 
            (Type = 0 AND 
             DocumentId IS NULL AND 
             (BookNumber IS NOT NULL AND 
              BookNumber != 0) AND 
             (ChapterNumber IS NOT NULL AND 
              ChapterNumber != 0) AND 
             Track IS NULL) OR 
            (Type = 1 AND 
             BookNumber IS NULL AND 
             ChapterNumber IS NULL AND 
             DocumentId IS NULL AND 
             Track IS NULL) OR 
            (Type IN (2, 3) AND 
             BookNumber IS NULL AND 
             ChapterNumber IS NULL) ) 
);


-- Table: Note
CREATE TABLE Note (
    NoteId          INTEGER NOT NULL
                            PRIMARY KEY,
    Guid            TEXT    NOT NULL
                            UNIQUE,
    UserMarkId      INTEGER,
    LocationId      INTEGER,
    Title           TEXT,
    Content         TEXT,
    LastModified    TEXT    NOT NULL
                            DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now') ),
    BlockType       INTEGER NOT NULL
                            DEFAULT 0,
    BlockIdentifier INTEGER,
    CHECK ( (BlockType = 0 AND 
             BlockIdentifier IS NULL) OR 
            ( (BlockType BETWEEN 1 AND 2) AND 
              BlockIdentifier IS NOT NULL) ),
    FOREIGN KEY (
        UserMarkId
    )
    REFERENCES UserMark (UserMarkId),
    FOREIGN KEY (
        LocationId
    )
    REFERENCES Location (LocationId) 
);


-- Table: PlaylistItem
CREATE TABLE PlaylistItem (
    PlaylistItemId       INTEGER NOT NULL
                                 PRIMARY KEY,
    Label                TEXT    NOT NULL,
    AccuracyStatement    INTEGER NOT NULL,
    StartTimeOffsetTicks INTEGER,
    EndTimeOffsetTicks   INTEGER,
    EndAction            INTEGER NOT NULL,
    ThumbnailFilename    TEXT,
    PlaylistMediaId      INTEGER NOT NULL,
    FOREIGN KEY (
        PlaylistMediaId
    )
    REFERENCES PlaylistMedia (PlaylistMediaId),
    CHECK (length(Label) > 0),
    CHECK (AccuracyStatement IN (0, 1, 2, 3) ),
    CHECK (EndAction IN (0, 1, 2, 3) ) 
);


-- Table: PlaylistItemChild
CREATE TABLE PlaylistItemChild (
    PlaylistItemChildId              INTEGER NOT NULL
                                             PRIMARY KEY,
    BaseDurationTicks                INTEGER NOT NULL,
    MarkerId                         INTEGER,
    MarkerLabel                      TEXT,
    MarkerStartTimeTicks             INTEGER,
    MarkerEndTransitionDurationTicks INTEGER,
    PlaylistItemId                   INTEGER NOT NULL,
    FOREIGN KEY (
        PlaylistItemId
    )
    REFERENCES PlaylistItem (PlaylistItemId),
    CHECK ( (MarkerId IS NULL AND 
             MarkerLabel IS NULL AND 
             MarkerStartTimeTicks IS NULL AND 
             MarkerEndTransitionDurationTicks IS NULL) OR 
            (MarkerId IS NOT NULL AND 
             MarkerLabel IS NOT NULL AND 
             MarkerStartTimeTicks IS NOT NULL) ) 
);


-- Table: PlaylistMedia
CREATE TABLE PlaylistMedia (
    PlaylistMediaId INTEGER NOT NULL
                            PRIMARY KEY,
    MediaType       INTEGER NOT NULL,
    Label           TEXT,
    Filename        TEXT    UNIQUE,
    LocationId      INTEGER,
    FOREIGN KEY (
        LocationId
    )
    REFERENCES Location (LocationId),
    CONSTRAINT MediaType_LocationId UNIQUE (
        MediaType,
        LocationId
    ),
    CHECK ( (LocationId IS NULL AND 
             Filename IS NOT NULL AND 
             Label IS NOT NULL) OR 
            (LocationId IS NOT NULL AND 
             Filename IS NULL AND 
             Label IS NULL) OR 
            (LocationId IS NOT NULL AND 
             Filename IS NOT NULL) ),
    CHECK (MediaType IN (1, 2, 3) ) 
);


-- Table: Tag
CREATE TABLE Tag (
    TagId         INTEGER NOT NULL
                          PRIMARY KEY,
    Type          INTEGER NOT NULL,
    Name          TEXT    NOT NULL,
    ImageFilename TEXT,
    UNIQUE (
        Type,
        Name
    ),
    CHECK (length(Name) > 0),
    CHECK (Type IN (0, 1, 2) ) 
);


-- Table: TagMap
CREATE TABLE TagMap (
    TagMapId       INTEGER NOT NULL
                           PRIMARY KEY,
    PlaylistItemId INTEGER,
    LocationId     INTEGER,
    NoteId         INTEGER,
    TagId          INTEGER NOT NULL,
    Position       INTEGER NOT NULL,
    FOREIGN KEY (
        TagId
    )
    REFERENCES Tag (TagId),
    FOREIGN KEY (
        PlaylistItemId
    )
    REFERENCES PlaylistItem (PlaylistItemId),
    FOREIGN KEY (
        LocationId
    )
    REFERENCES Location (LocationId),
    FOREIGN KEY (
        NoteId
    )
    REFERENCES Note (NoteId),
    CONSTRAINT TagId_Position UNIQUE (
        TagId,
        Position
    ),
    CONSTRAINT TagId_NoteId UNIQUE (
        TagId,
        NoteId
    ),
    CONSTRAINT TagId_LocationId UNIQUE (
        TagId,
        LocationId
    ),
    CHECK ( (NoteId IS NULL AND 
             LocationId IS NULL AND 
             PlaylistItemId IS NOT NULL) OR 
            (LocationId IS NULL AND 
             PlaylistItemId IS NULL AND 
             NoteId IS NOT NULL) OR 
            (PlaylistItemId IS NULL AND 
             NoteId IS NULL AND 
             LocationId IS NOT NULL) ) 
);


-- Table: UserMark
CREATE TABLE UserMark (
    UserMarkId   INTEGER NOT NULL
                         PRIMARY KEY,
    ColorIndex   INTEGER NOT NULL,
    LocationId   INTEGER NOT NULL,
    StyleIndex   INTEGER NOT NULL,
    UserMarkGuid TEXT    NOT NULL
                         UNIQUE,
    Version      INTEGER NOT NULL,
    FOREIGN KEY (
        LocationId
    )
    REFERENCES Location (LocationId) 
);


-- Index: IX_BlockRange_UserMarkId
CREATE INDEX IX_BlockRange_UserMarkId ON BlockRange (
    UserMarkId
);


-- Index: IX_Location_KeySymbol_MepsLanguage_BookNumber_ChapterNumber
CREATE INDEX IX_Location_KeySymbol_MepsLanguage_BookNumber_ChapterNumber ON Location (
    KeySymbol,
    MepsLanguage,
    BookNumber,
    ChapterNumber
);


-- Index: IX_Location_MepsLanguage_DocumentId
CREATE INDEX IX_Location_MepsLanguage_DocumentId ON Location (
    MepsLanguage,
    DocumentId
);


-- Index: IX_Note_LastModified_LocationId
CREATE INDEX IX_Note_LastModified_LocationId ON Note (
    LastModified,
    LocationId
);


-- Index: IX_Note_LocationId_BlockIdentifier
CREATE INDEX IX_Note_LocationId_BlockIdentifier ON Note (
    LocationId,
    BlockIdentifier
);


-- Index: IX_Tag_Name_Type_TagId
CREATE INDEX IX_Tag_Name_Type_TagId ON Tag (
    Name,
    Type,
    TagId
);


-- Index: IX_TagMap_LocationId_TagId_Position
CREATE INDEX IX_TagMap_LocationId_TagId_Position ON TagMap (
    LocationId,
    TagId,
    Position
);


-- Index: IX_TagMap_NoteId_TagId_Position
CREATE INDEX IX_TagMap_NoteId_TagId_Position ON TagMap (
    NoteId,
    TagId,
    Position
);


-- Index: IX_TagMap_PlaylistItemId_TagId_Position
CREATE INDEX IX_TagMap_PlaylistItemId_TagId_Position ON TagMap (
    PlaylistItemId,
    TagId,
    Position
);


-- Index: IX_TagMap_TagId
CREATE INDEX IX_TagMap_TagId ON TagMap (
    TagId
);


-- Index: IX_UserMark_LocationId
CREATE INDEX IX_UserMark_LocationId ON UserMark (
    LocationId
);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
