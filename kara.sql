create database KaraokeOnline;
GO

use KaraokeOnline;

create table Account(
	UserID int identity(1,1) primary key,
	UserName nvarchar(100) unique not null,
	UserPassword nvarchar(100)not null,
	LastName nvarchar(100)not null,
	FirstName nvarchar(100)not null,
	Email nvarchar(100)not null,		
	Roles varchar(10)not null, 
);

create table Languages(
	LanguageID int identity(1,1) primary key,
	LanguageName nvarchar(50)not null,
)
GO

create table Catalogue(
	CatalogID int identity(1,1) primary key,
	CatalogName nvarchar(50)not null,
	LanguageID int not null,
	FOREIGN KEY (LanguageID) REFERENCES Languages(LanguageID)  
)

create table Song(
	SongID int identity(1,1) primary key,
	SongName nvarchar(100)not null,
	SongArtist nvarchar(100)not null,
	SongURL nvarchar(max)not null,
	ViewSong int,
	CatalogID int not null,
	LanguageID int not null,
	UserUpload int not null,
	Opens bit not null,
	TimeUpload datetime not null DEFAULT GETDATE(),
	FOREIGN KEY (UserUpload) REFERENCES Account(UserID), 
	FOREIGN KEY (CatalogID) REFERENCES Catalogue(CatalogID),
	FOREIGN KEY (LanguageID) REFERENCES Languages(LanguageID)    
)
GO

create table Playlist(
	PlaylistID int identity(1,1) primary key,
	PlaylistName nvarchar(100)not null,
	UserID int,
	TimeCreate datetime not null DEFAULT GETDATE(),
	FOREIGN KEY (UserID) REFERENCES Account(UserID), 
)

create table PlaylistSong(
	PlaylistID int,
	SongID int,
	TimeAdd datetime DEFAULT GETDATE(),
	unique(PlaylistID, SongID),
	primary key(PlaylistID, SongID),
	FOREIGN KEY (SongID) REFERENCES Song(SongID) ON DELETE CASCADE,
	FOREIGN KEY (PlaylistID) REFERENCES Playlist(PlaylistID) ON DELETE CASCADE,  
)

INSERT INTO Account(UserName,UserPassword,LastName,FirstName,Email,Roles) VALUES('Admin','827CCB0EEA8A706C4C34A16891F84E7B',N'Phạm Văn',N'Hoàng','hoang@gmail.com','Admin');
INSERT INTO Account(UserName,UserPassword,LastName,FirstName,Email,Roles) VALUES('Guess','827CCB0EEA8A706C4C34A16891F84E7B',N'Cao Văn',N'Thấp','thap_cao@gmail.com','Guest');


INSERT INTO Languages(LanguageName) VALUES('Vietnamese');
INSERT INTO Languages(LanguageName) VALUES('English');
GO


INSERT INTO Catalogue(CatalogName,LanguageID) VALUES(N'Nhạc Trẻ',1);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES(N'Nhạc Đỏ',1);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES(N'Nhạc Vàng',1);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES(N'Nhạc Dân Ca',1);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES(N'Nhạc Thiếu Nhi',1);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES('Pop',2);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES('Rock',2);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES('Jazz',2);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES('R&B',2);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES('Country',2);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES('Folk',2);
INSERT INTO Catalogue(CatalogName,LanguageID) VALUES('Classical',2);
GO


INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES('Sugar','Maroon 5',N'https://www.youtube.com/embed/09R8_2nJtjg?rel=0',0,6,2,1,1,'20170321 10:34:09 AM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES('One More Night','Maroon 5',N'https://www.youtube.com/embed/fwK7ggA3-bU?rel=0',0,6,2,1,1,'20170321 11:34:09 AM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES('Animals','Maroon 5',N'https://www.youtube.com/embed/qpgTC9MDx1o?rel=0',0,6,2,1,1,'20170321 12:34:09 AM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES('Just The Way You Are','Bruno Mars',N'https://www.youtube.com/embed/LjhCEhWiKXk?rel=0',0,6,2,1,1,'20170321 1:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES('Grenade ','Bruno Mars',N'https://www.youtube.com/embed/SR6iYWJxHqs?rel=0',0,6,2,1,1,'20170321 2:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES('It Will Rain','Bruno Mars',N'https://www.youtube.com/embed/W-w3WfgpcGg?rel=0',0,6,2,1,1,'20170321 3:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES('Thinking Out Loud ','Ed Sheeran',N'https://www.youtube.com/embed/lp-EO5I60KA?rel=0',0,6,2,1,1,'20170321 4:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES('Let Her Go','Passenger',N'https://www.youtube.com/embed/RBumgq5yVrA?rel=0',0,6,2,1,1,'20170321 5:34:09 PM');

INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Nơi Này Có Anh',N'Sơn Tùng M-TP',N'https://www.youtube.com/embed/FN7ALfpGxiI?rel=0',0,1,1,1,1,'20170322 10:34:09 AM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Lạc Trôi',N'Sơn Tùng M-TP',N'https://www.youtube.com/embed/Llw9Q6akRo4?rel=0',0,1,1,1,1,'20170322 11:34:09 AM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Buông Đôi Tay Nhau Ra',N'Sơn Tùng M-TP',N'https://www.youtube.com/embed/LCyo565N_5w?rel=0',0,1,2,1,1,'20170322 12:34:09 AM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Kìa Con Bướm Vàng',N'Xuân Mai',N'https://www.youtube.com/embed/1RANSHBoBdE?rel=0',0,5,1,1,1,'20170324 1:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Hổng Dám Đâu',N'Xuân Mai',N'https://www.youtube.com/embed/bPqS9TOFpjA?rel=0',0,5,1,1,1,'20170323 2:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Duyên Phận',N'Như Quỳnh',N'https://www.youtube.com/embed/W-w3WfgpcGg?rel=0',0,3,1,1,1,'20170322 3:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Vùng Lá Me Bay',N'Như Quỳnh',N'https://www.youtube.com/embed/ycGfvA1vkR8?rel=0',0,3,1,1,1,'20170322 4:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Năm Anh Em Trên Một Chiếc Xe Tăng',N'Nhiều Ca Sĩ ',N'https://www.youtube.com/embed/5Hy9D8nT32w?rel=0',0,2,1,1,1,'20170325 5:34:09 PM');


INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Too Much, Too Young, Too Fast',N'Airbourne',N'https://www.youtube.com/embed/uANVBPVaf-g?rel=0',0,7,2,1,1,'20170323 10:34:09 AM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Back In The Game',N'Airbourne',N'https://www.youtube.com/embed/FlPalDkWsuA?rel=0"',0,7,2,1,1,'20170323 11:34:09 AM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Quicksand Jesus',N'Skid Row',N'https://www.youtube.com/embed/L8fYiqKbv7g?rel=0',0,7,2,1,1,'20170323 12:34:09 AM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Baby',N'Justin Bieber',N'https://www.youtube.com/embed/kffacxfA7G4?rel=0',0,6,1,1,1,'20170325 1:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Sorry',N'Justin Biebe',N'https://www.youtube.com/embed/fRh_vgS2dFE?rel=0',0,6,1,1,1,'20170324 2:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Faded',N'Alan Walker',N'https://www.youtube.com/embed/60ItHLz5WEA?rel=0',0,9,1,1,1,'20170323 3:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Alone',N'Alan Walker',N'https://www.youtube.com/embed/1-xGerv5FOk?rel=0',0,9,1,1,1,'20170323 4:34:09 PM');
INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload) VALUES(N'Let Me Love You',N'DJ Snake ft. Justin Bieber',N'https://www.youtube.com/embed/SMs0GnYze34?rel=0',0,6,1,1,1,'20170326 5:34:09 PM');



INSERT INTO Playlist(PlaylistName,UserID,TimeCreate) VALUES(N'Nhạc Sếp Tùng',2,'20170323 5:34:09 PM');
INSERT INTO Playlist(PlaylistName,UserID) VALUES(N'Nhạc US-UK',2);
INSERT INTO Playlist(PlaylistName,UserID,TimeCreate) VALUES(N'Nhạc Việt Nam',2,'20170323 6:30:09 PM');
--Stored Procedure
GO



CREATE PROCEDURE Create_Playlist
@PlaylistName nvarchar(100), 
@UserID int 
AS
BEGIN
	INSERT INTO Playlist(PlaylistName,UserID) 
	VALUES(@PlaylistName,@UserID);
END
GO

CREATE PROCEDURE Update_Playlist
@PlaylistName nvarchar(100), 
@PlaylistID int 
AS
BEGIN
	Update Playlist
	Set PlaylistName = @PlaylistName
	where PlaylistID = @PlaylistID
END
GO

CREATE PROCEDURE Delete_Playlist
@PlaylistID int 
AS
BEGIN
	Delete Playlist
	where PlaylistID = @PlaylistID
END
GO


CREATE PROCEDURE Create_PlaylistSong
@PlaylistID int, 
@SongID int 
AS
BEGIN
	INSERT INTO PlaylistSong(PlaylistID,SongID) 
	VALUES(@PlaylistID,@SongID);
END
GO

CREATE PROCEDURE Delete_PlaylistSong
@PlaylistID int,
@SongID int 
AS
BEGIN
	Delete PlaylistSong
	where PlaylistID = @PlaylistID AND SongID = @SongID
END
GO


CREATE PROCEDURE AllSongCreateByUser
@UserID int 
AS
BEGIN
	Select *
	From Song s
	where s.UserUpload = @UserID
END
GO

CREATE PROCEDURE Create_Song
@SongName nvarchar(100), 
@SongArtist nvarchar(100), 
@SongURL nvarchar(100), 
@CatalogID int,
@LanguageID int,
@UserUpload int,
@Opens bit 
AS
BEGIN
	INSERT INTO Song(SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens)
	VALUES(@SongName,@SongArtist,@SongURL,0,@CatalogID,@LanguageID,@UserUpload,@Opens);
END
GO





CREATE PROCEDURE Delete_Song
@SongID int 
AS
BEGIN
	Delete Song
	where SongID = @SongID
END
GO

CREATE PROCEDURE Update_Song
@SongID int,
@SongName nvarchar(100), 
@SongArtist nvarchar(100), 
@SongURL nvarchar(100) 
AS
BEGIN
	Update Song
	Set SongName = @SongName, SongArtist = @SongArtist, @SongURL = @SongURL
	where SongID = @SongID
END
GO

create PROCEDURE CheckLogin
@Name nvarchar(100), 
@Pass nvarchar(100) 
AS
BEGIN
	SELECT *	
	FROM Account a
	Where a.UserName = @Name  COLLATE Latin1_General_CS_AS  AND a.UserPassword = @Pass
END
GO

CREATE PROCEDURE CheckSongInPlaylist
@SongID int,
@UserID int
AS
BEGIN
	SELECT *
	FROM Playlist p
	Where p.UserID = @UserID AND p.PlaylistID not in(
				SELECT DISTINCT  p.PlaylistID
			    FROM Playlist p INNER JOIN  PlaylistSong ps ON p.PlaylistID = ps.PlaylistID
				Where SongID = @SongID
	)
	ORDER BY p.TimeCreate DESC
END
GO

CREATE PROCEDURE ChangeProlife
@FirstName nvarchar(100), 
@LastName nvarchar(100),
@UserID int
AS
BEGIN
	Update Account 	
	Set FirstName = @FirstName,LastName = @LastName
	Where UserID = @UserID
END
GO

create PROCEDURE ChangePass
@Currentpass nvarchar(100),
@Newpass nvarchar(100),
@UserID int
AS
BEGIN
	if exists (select * From Account Where UserID = @UserID AND UserPassword = @Currentpass) 
	BEGIN
		Update Account 	
		Set UserPassword = @Newpass
		Where UserID = @UserID
	END
	RAISERROR('Wrong password. Try again',11,1)
END
GO

CREATE PROCEDURE Create_User
@UserName nvarchar(100), 
@UserPassword nvarchar(100), 
@LastName nvarchar(100), 
@FirstName nvarchar(100),
@Email nvarchar(100)
AS
BEGIN
	INSERT INTO Account(UserName,UserPassword,FirstName,LastName,Email,Roles)
	VALUES(@UserName,@UserPassword,@FirstName,@LastName,@Email,'Guest');
END
GO

CREATE PROCEDURE GetSongInPlaylist
@PlaylistID int
AS
BEGIN
	SELECT s.SongID,SongName,SongArtist,SongURL,ViewSong,CatalogID,LanguageID,UserUpload,Opens,TimeUpload	
	FROM PlaylistSong p INNER JOIN  Song s ON p.SongID = s.SongID
	Where p.PlaylistID = @PlaylistID
	ORDER BY p.TimeAdd DESC
END
GO


create PROCEDURE GetAllUser
AS
BEGIN
	SELECT *
	FROM Account a
	Where a.Roles = 'Guest'
END
GO

exec GetAllUser

exec Create_Playlist @PlaylistName=N'Tình Ca Bất Hủ', @UserID = 2

exec Update_Playlist @PlaylistName=N'Tình Ca Bất Hủ Ngàn Thu Le Lói', @PlaylistID = 4


exec Create_PlaylistSong @PlaylistID =	2, @SongID = 1

exec Create_PlaylistSong @PlaylistID =	2, @SongID = 2

exec Delete_PlaylistSong @PlaylistID =	2, @SongID = 20

exec CheckSongInPlaylist @UserID = 2, @SongID = 24

exec Create_Song @SongName = 'test', @SongArtist = 'test', @SongURL = 'test', @CatalogID = 1,@LanguageID = 1,@UserUpload = 2,@Opens = 1 
GO


CREATE TRIGGER MaxSongInPlaylist--Tên Trigger
ON PlaylistSong
FOR INSERT
AS
BEGIN
	DECLARE @PlaylistID int = (SELECT PlaylistID FROM inserted)
	DECLARE @Number int
	Set @Number = (SELECT COUNT(p.SongID) FROM PlaylistSong p WHERE p.PlaylistID =  @PlaylistID)
	if(@Number > 9)
	BEGIN
	ROLLBACK TRAN 
	RAISERROR('Error: Full Playlist',11,1)
	END
END




exec ChangePass @Currentpass = 2, @Newpass = 24,@UserID =2

select *
from Account a
where a.UserName = 'Admin' COLLATE Latin1_General_CS_AS 

delete Account
where Account.UserID = 5