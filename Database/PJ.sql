USE [master]
GO
/****** Object:  Database [PJ]    Script Date: 4/22/2014 5:13:43 PM ******/
CREATE DATABASE [PJ]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'PJ', FILENAME = N'C:\Program Files (x86)\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\PJ.mdf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'PJ_log', FILENAME = N'C:\Program Files (x86)\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\PJ_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [PJ] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [PJ].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [PJ] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [PJ] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [PJ] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [PJ] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [PJ] SET ARITHABORT OFF 
GO
ALTER DATABASE [PJ] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [PJ] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [PJ] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [PJ] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [PJ] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [PJ] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [PJ] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [PJ] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [PJ] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [PJ] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [PJ] SET  DISABLE_BROKER 
GO
ALTER DATABASE [PJ] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [PJ] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [PJ] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [PJ] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [PJ] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [PJ] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [PJ] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [PJ] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [PJ] SET  MULTI_USER 
GO
ALTER DATABASE [PJ] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [PJ] SET DB_CHAINING OFF 
GO
ALTER DATABASE [PJ] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [PJ] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [PJ]
GO
/****** Object:  StoredProcedure [dbo].[stp_Assign_Remove_MenuItems_Role]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [stp_Assign_Remove_MenuItems_Role] 1,2,'13,14',1
CREATE PROCEDURE [dbo].[stp_Assign_Remove_MenuItems_Role] 
	@InstanceId int,
	@RoleId int,
	@MenuItems varchar(max),
	@CreatedBy int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--declare @mitems varchar(max)
declare @tbl table(Id int)
--set @mitems = '12,13,14,49,15,31,35,36,37'
insert into @tbl(Id) select value from Split(@MenuItems,',')

Insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
select @InstanceId,@RoleId,Id,@CreatedBy,GETDATE() from @tbl where Id not in (select MenuId from RoleMenu where RoleId=@RoleId)

update T set T.Status=0
from RoleMenu T where MenuId in	(select Id from @tbl) and Status=1 and InstanceId = @InstanceId and RoleId = @RoleId

update T set T.Status=1
from RoleMenu T where MenuId not in	(select Id from @tbl) and InstanceId = @InstanceId and RoleId = @RoleId
declare @patientId int
declare @curParent Cursor
set @curParent = CURSOR for select Id from Menu where ParentId IS NULL and InstanceId = @InstanceId 
open @curParent
fetch next from @curParent into @patientId
while @@FETCH_STATUS=0
BEGIN
IF EXISTS(Select 1 from RoleMenu where RoleId=@RoleId and MenuId in(select Id from Menu where ParentId=@patientId) and ISNULL(Status,0)=0 and InstanceId = @InstanceId)
begin
IF NOT EXISTS(select 1 from RoleMenu where MenuId = @patientId and InstanceId = @InstanceId and RoleId = @RoleId)
BEGIN
Insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
values(@InstanceId,@RoleId,@patientId,@CreatedBy,GETDATE())
END
ELSE
BEGIN
update RoleMenu set Status=0 where MenuId=@patientId and InstanceId = @InstanceId and RoleId = @RoleId
END
end
else
begin
 update RoleMenu set Status=1 where MenuId=@patientId and InstanceId = @InstanceId and RoleId = @RoleId
end

fetch next from @curParent into @patientId
END
close @curParent
deallocate @curParent

EXEC stp_Assign_Remove_MenuItems_User @InstanceId,@CreatedBy

select 1

END

GO
/****** Object:  StoredProcedure [dbo].[stp_Assign_Remove_MenuItems_User]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[stp_Assign_Remove_MenuItems_User]
	-- Add the parameters for the stored procedure here
	@InstanceId int,
	@CreatedBy int
AS
BEGIN
declare @RoleMenuId int
declare @RoleId int
declare @MenuId int

declare @curParent Cursor
set @curParent = CURSOR for 
SELECT Id, RoleId, MenuId
	FROM RoleMenu
	WHERE (InstanceId = @InstanceId) AND (ISNULL(Status, 0) = 0)

open @curParent
fetch next from @curParent into @RoleMenuId,@RoleId,@MenuId
while @@FETCH_STATUS=0
BEGIN
	delete from UserMenu where instanceid=@InstanceId and RoleId = @RoleId and MenuId= @MenuId

	declare @FromDate date
	declare @ToDate date
	select @FromDate = LicenseStartDate , @ToDate = LicenseEndDate from Instance where Id = @InstanceId

	insert into UserMenu (InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	select @InstanceId,Id,@RoleId,@MenuId,@FromDate,@ToDate,1,@CreatedBy,GETDATE() 
	from [User] where InstanceId = @InstanceId and RoleId = @RoleId

	delete from [Right] where UserMenuId in (select Id from usermenu where InstanceId = @InstanceId and RoleId =@RoleId and MenuId = @MenuId)
	insert into [Right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
	select mar.MenuRightId,1,um.Id,@CreatedBy,GETDATE() from usermenu um join MenuAccessRight mar on um.MenuId = mar.MenuId
	where um.InstanceId = @InstanceId and um.RoleId =@RoleId and um.MenuId = @MenuId


	fetch next from @curParent into @RoleMenuId,@RoleId,@MenuId
END
END

GO
/****** Object:  StoredProcedure [dbo].[stp_Get_Menuitems_By_Role_Id]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[stp_Get_Menuitems_By_Role_Id] 
	-- Add the parameters for the stored procedure here
	@InstanceId int,
	@RoleId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  select m.Id, m.ParentId,m.Name,m.GroupId,m.[Order],m.level,1 as checked from menu m
 where id in(select menuid from RoleMenu where InstanceId=@InstanceId and RoleId=@RoleId and ISNULL(Status,0)=0) and m.InstanceId =@InstanceId
 UNION ALL
 select m.Id, m.ParentId,m.Name,m.GroupId,m.[Order],m.level,0 as checked from menu m
 where id not in(select menuid from RoleMenu where InstanceId=@InstanceId and RoleId=@RoleId and ISNULL(Status,0)=0) and m.InstanceId =@InstanceId
 
END

GO
/****** Object:  StoredProcedure [dbo].[stp_Intial_Menus_For_Admin]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[stp_Intial_Menus_For_Admin] 
@InstanceId int,
@RoleId int,
@UserId int,
@FromDate date,
@Todate date
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
declare @ParentMenuIdentity integer
declare @ChildMenuIdentity integer
declare @RoleMenuIdentity integer
declare @UserMenuIdentity integer
    -- Insert statements for procedure here
	INSERT [dbo].[Menu] ([InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, NULL, N'Home', N'Welcome', N'Admin', NULL, 0, 0, NULL)
set @ParentMenuIdentity  = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ParentMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ParentMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()

INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, @ParentMenuIdentity, N'Dashboard', N'Welcome', N'Admin', 1, 0, 1, NULL)
set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()
INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, @ParentMenuIdentity, N'Change Password', N'ChangePwd', N'Shared', 2, 0, 1, NULL)
set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(1,0,@UserMenuIdentity,1,GETDATE())


INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, NULL, N'Admin Module', N'ManageUsers', N'Admin', NULL, 1, 0, NULL)
set @ParentMenuIdentity  = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ParentMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ParentMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(2,1,@UserMenuIdentity,1,GETDATE())
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(3,1,@UserMenuIdentity,1,GETDATE())

INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, @ParentMenuIdentity, N'Manage Users', N'ManageUsers', N'Admin', 5, 0, 1, NULL)
set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(2,1,@UserMenuIdentity,1,GETDATE())
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(3,1,@UserMenuIdentity,1,GETDATE())

INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, @ParentMenuIdentity, N'Manage Notices', N'Notices', N'Admin', 1, 1, 1, NULL)
set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(11,1,@UserMenuIdentity,1,GETDATE())
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(12,1,@UserMenuIdentity,1,GETDATE())
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(13,1,@UserMenuIdentity,1,GETDATE())

INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, @ParentMenuIdentity, N'Send SMS', N'MultiSMS', N'SMS', 1, 2, 1, NULL)
set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()

INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status])
 VALUES (@InstanceId, @ParentMenuIdentity, N'Bulk Upload Users', N'BulkUploadUsers', N'BulkUpload', 9, 0, 1, NULL)
 set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()

INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status])
 VALUES (@InstanceId, @ParentMenuIdentity, N'Manage Roles', N'ManageRoles', N'Admin', 5, 1, 1, NULL)
 set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()

 
INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, NULL, N'Online Test', NULL, NULL, NULL, 2, 0, NULL)
set @ParentMenuIdentity  = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ParentMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ParentMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()

INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, @ParentMenuIdentity, N'My Tests', N'ManageTests', N'OnlineTest', 7, 1, 1, NULL)
set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(5,1,@UserMenuIdentity,1,GETDATE())
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(6,1,@UserMenuIdentity,1,GETDATE())
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(8,1,@UserMenuIdentity,1,GETDATE())
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(7,1,@UserMenuIdentity,1,GETDATE())
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(9,1,@UserMenuIdentity,1,GETDATE())
insert into [right](MenuRightId,Flag,UserMenuId,CreatedBy,CreatedDate)
values(10,1,@UserMenuIdentity,1,GETDATE())


INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, @ParentMenuIdentity, N'Categories', N'ManageCategory', N'OnlineTest', 7, 0, 1, NULL)
set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()

INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) 
VALUES (@InstanceId, NULL, N'Attendance', N'PostAttendance', N'Attendance', NULL, 3, 0, NULL)
set @ParentMenuIdentity  = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ParentMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ParentMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()

INSERT [dbo].[Menu] ( [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status])
 VALUES (@InstanceId, @ParentMenuIdentity, N'Post Attendance', N'PostAttendance', N'Attendance', 8, 0, 1, NULL)
set @ChildMenuIdentity = SCOPE_IDENTITY()
insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate)
	values(@InstanceId,@RoleId,@ChildMenuIdentity,1,GETDATE())
set @RoleMenuIdentity = SCOPE_IDENTITY()	
insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	values(@InstanceId,@UserId,@RoleId,@ChildMenuIdentity,@FromDate,@Todate,1,1,GETDATE())
set @UserMenuIdentity = SCOPE_IDENTITY()

	
	--insert into RoleMenu(InstanceId,RoleId,MenuId,CreatedBy,CreatedDate,Status)
	--select @InstanceId,@RoleId,Id,1,GETDATE(),Status from Menu where InstanceId=@InstanceId
	
	--insert into UserMenu(InstanceId,UserId,RoleId,MenuId,FromDate,ToDate,Flag,CreatedBy,CreatedDate)
	--select @InstanceId,@UserId,@RoleId,Id,@FromDate,@Todate,1,1,GETDATE() from Menu where InstanceId=@InstanceId
	
	insert into Role(InstanceId,Role,RoleDesc,CreatedBy,CreatedDate)
	values(@InstanceId,'Student','Student',1,GETDATE())
	
	insert into Role(InstanceId,Role,RoleDesc,CreatedBy,CreatedDate)
	values(@InstanceId,'Teacher','Teacher',1,GETDATE())
	
	select 1
END

GO
/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Split]      
(       
 @List varchar(Max),      
 @SplitOn nvarchar(1)      
)      
RETURNS @RtnValue table (      
 Id int identity(1,1),      
 Value varchar(max)      
)      
AS      
BEGIN      
 While (Charindex(@SplitOn,@List)>0)      
 Begin       
  Insert Into @RtnValue (value)      
  Select       
   Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1)))       
  Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))      
 End       
       
 Insert Into @RtnValue (Value)      
    Select Value = ltrim(rtrim(@List))      
      
    Return      
END

GO
/****** Object:  Table [dbo].[Dealer]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Dealer](
	[DealerId] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[DealerName] [varchar](50) NOT NULL,
	[CompanyName] [varchar](50) NOT NULL,
	[CompanyShortForm] [varchar](10) NULL,
	[Address] [varchar](500) NULL,
	[City] [varchar](20) NULL,
	[State] [varchar](20) NULL,
	[PinCode] [varchar](6) NULL,
	[CompanyVATOrTinNo] [varchar](20) NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_Dealer] PRIMARY KEY CLUSTERED 
(
	[DealerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[GoldRates]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GoldRates](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[GoldCity] [varchar](100) NOT NULL,
	[URL] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_GoldRates] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[GoldRatesManual]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GoldRatesManual](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[City] [varchar](500) NOT NULL,
	[GoldWeight] [varchar](50) NOT NULL,
	[GoldPrice] [varchar](100) NOT NULL,
	[SilverWeight] [varchar](50) NOT NULL,
	[SilverPrice] [varchar](100) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_GoldRatesManual] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Instance]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Instance](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](200) NOT NULL,
	[ParentInstance] [int] NULL,
	[Address] [varchar](2000) NULL,
	[PIN] [varchar](50) NULL,
	[Phone] [varchar](20) NULL,
	[Mobile] [varchar](12) NULL,
	[CreatedDate] [datetime] NOT NULL,
	[LicenseStartDate] [date] NULL,
	[LicenseEndDate] [date] NULL,
	[Status] [bit] NULL,
	[GoldCityId] [int] NULL,
	[Domain] [nvarchar](500) NULL,
 CONSTRAINT [PK_Instance] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Log4Net_Error]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Log4Net_Error](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NOT NULL,
	[Thread] [varchar](255) NOT NULL,
	[Level] [varchar](50) NOT NULL,
	[Logger] [varchar](255) NOT NULL,
	[Message] [varchar](4000) NOT NULL,
	[Exception] [varchar](2000) NOT NULL,
	[UserID] [varchar](200) NOT NULL,
 CONSTRAINT [PK_Log4Net_Error] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Lot]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Lot](
	[LotId] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[LotName] [varchar](10) NOT NULL,
	[Weight] [decimal](18, 2) NULL,
	[NoOfPieces] [int] NULL,
	[ProductGroupId] [int] NOT NULL,
	[DealerId] [int] NULL,
	[IsMRP] [bit] NULL,
	[MRP] [decimal](18, 2) NULL,
	[DiffAllowed] [decimal](18, 2) NULL,
 CONSTRAINT [PK_Lot] PRIMARY KEY CLUSTERED 
(
	[LotId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LotStatus]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LotStatus](
	[StatusId] [int] IDENTITY(1,1) NOT NULL,
	[EnumValue] [varchar](50) NOT NULL,
 CONSTRAINT [PK_LotStatus] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LotUserMapping]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LotUserMapping](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LotId] [int] NOT NULL,
	[StatusId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
 CONSTRAINT [PK_LotUserMapping] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Menu]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Menu](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NULL,
	[ParentId] [int] NULL,
	[Name] [varchar](100) NOT NULL,
	[Action] [varchar](200) NULL,
	[Controller] [varchar](200) NULL,
	[GroupId] [int] NULL,
	[Order] [int] NOT NULL,
	[Level] [int] NOT NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_Menu] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MenuAccessRight]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MenuAccessRight](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MenuId] [int] NOT NULL,
	[MenuRightId] [int] NOT NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_MenuAccessRight] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MenuGroup]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MenuGroup](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NULL,
	[GroupName] [varchar](100) NULL,
	[GroupShortName] [varchar](100) NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_MenuGroup] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MenuRight]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MenuRight](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MenuRight] [varchar](100) NOT NULL,
	[MenuRightDescription] [varchar](500) NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_MenuRight] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Product]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Product](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[ProductName] [varchar](300) NOT NULL,
	[ShortForm] [varchar](100) NULL,
	[ValueAddedByPerc] [decimal](18, 3) NULL,
	[ValueAddedFixed] [decimal](18, 3) NULL,
	[MakingChargesPerGram] [decimal](18, 3) NULL,
	[MakingChargesFixed] [decimal](18, 3) NULL,
	[IsStone] [bit] NOT NULL,
	[IsWeightless] [bit] NOT NULL,
	[ProductCategoryId] [int] NOT NULL,
	[ProductGroupId] [int] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ProductCategory]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProductCategory](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[ProductCategory] [varchar](100) NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_ProductCategory] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ProductGroup]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProductGroup](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[ProductGroup] [varchar](100) NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_ProductGroup] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Right]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Right](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MenuRightId] [int] NOT NULL,
	[Flag] [bit] NOT NULL,
	[UserMenuId] [int] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_Right] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Role]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Role](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NULL,
	[Role] [varchar](50) NOT NULL,
	[RoleDesc] [varchar](500) NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_Role] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RoleMenu]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RoleMenu](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[RoleId] [int] NOT NULL,
	[MenuId] [int] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_RoleMenu] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SiteLog]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SiteLog](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TimeStamp] [datetime] NOT NULL,
	[Action] [varchar](1000) NOT NULL,
	[Controller] [varchar](1000) NOT NULL,
	[IPAddress] [varchar](1000) NULL,
	[URL] [varchar](1000) NULL,
	[HostAddress] [varchar](1000) NULL,
	[UserID] [varchar](1000) NULL,
 CONSTRAINT [PK_SiteLog] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Stone]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Stone](
	[StoneId] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[StoneName] [varchar](30) NOT NULL,
	[StoneShortForm] [varchar](10) NOT NULL,
	[StonePerCarat] [int] NULL,
	[IsStoneWeightless] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_Stone] PRIMARY KEY CLUSTERED 
(
	[StoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[User]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[User](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](500) NOT NULL,
	[Password] [nvarchar](500) NOT NULL,
	[RoleId] [int] NULL,
	[Email] [varchar](100) NULL,
	[InstanceId] [int] NULL,
	[IsApproved] [bit] NOT NULL,
	[IsLockedOut] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[LastLoginDate] [datetime] NULL,
	[LastPasswordChangedDate] [datetime] NULL,
	[LastLockedOutDate] [datetime] NULL,
	[FailedPasswordAttemptCount] [int] NULL,
	[ChangePwdonLogin] [bit] NULL,
	[Comment] [nvarchar](500) NULL,
 CONSTRAINT [PK_Users_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UserDetails]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserDetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Address] [varchar](300) NULL,
	[City] [varchar](100) NULL,
	[State] [varchar](50) NULL,
	[PinCode] [varchar](10) NULL,
	[Mobile] [varchar](20) NULL,
	[Phone] [varchar](20) NULL,
 CONSTRAINT [PK_UserDetails] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UserMenu]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserMenu](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[RoleId] [int] NOT NULL,
	[MenuId] [int] NOT NULL,
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL,
	[Flag] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_UserMenu] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[LotUserMappingView]    Script Date: 4/22/2014 5:13:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[LotUserMappingView]
AS
SELECT     L.LotId,L.LotName, U.UserName, LS.EnumValue AS Status,L.InstanceId
FROM         dbo.LotUserMapping AS LUM INNER JOIN
                      dbo.Lot AS L ON L.LotId = LUM.LotId INNER JOIN
                      dbo.[User] AS U ON U.Id = LUM.UserId INNER JOIN
                      dbo.LotStatus AS LS ON LS.StatusId = LUM.StatusId



GO
SET IDENTITY_INSERT [dbo].[Dealer] ON 

GO
INSERT [dbo].[Dealer] ([DealerId], [InstanceId], [DealerName], [CompanyName], [CompanyShortForm], [Address], [City], [State], [PinCode], [CompanyVATOrTinNo], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (1, 1, N'd1', N'c1', NULL, NULL, NULL, NULL, NULL, NULL, 4, CAST(0x0000A3100133D651 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Dealer] ([DealerId], [InstanceId], [DealerName], [CompanyName], [CompanyShortForm], [Address], [City], [State], [PinCode], [CompanyVATOrTinNo], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (2, 1, N'd1', N'c1', NULL, NULL, NULL, NULL, NULL, NULL, 4, CAST(0x0000A3100136733F AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Dealer] ([DealerId], [InstanceId], [DealerName], [CompanyName], [CompanyShortForm], [Address], [City], [State], [PinCode], [CompanyVATOrTinNo], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (3, 1, N'd1', N'c1', NULL, NULL, NULL, NULL, NULL, NULL, 4, CAST(0x0000A310013691DD AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Dealer] ([DealerId], [InstanceId], [DealerName], [CompanyName], [CompanyShortForm], [Address], [City], [State], [PinCode], [CompanyVATOrTinNo], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (4, 1, N'd1', N'c1', NULL, NULL, NULL, NULL, NULL, NULL, 4, CAST(0x0000A3100136C8A9 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Dealer] ([DealerId], [InstanceId], [DealerName], [CompanyName], [CompanyShortForm], [Address], [City], [State], [PinCode], [CompanyVATOrTinNo], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (5, 1, N'd1', N'c1', NULL, NULL, NULL, NULL, NULL, NULL, 4, CAST(0x0000A31001377D0D AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Dealer] ([DealerId], [InstanceId], [DealerName], [CompanyName], [CompanyShortForm], [Address], [City], [State], [PinCode], [CompanyVATOrTinNo], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (6, 1, N'd1u', N'c1', NULL, NULL, NULL, NULL, NULL, NULL, 4, CAST(0x0000A310013EBE22 AS DateTime), 4, CAST(0x0000A310013ED612 AS DateTime), 1)
GO
INSERT [dbo].[Dealer] ([DealerId], [InstanceId], [DealerName], [CompanyName], [CompanyShortForm], [Address], [City], [State], [PinCode], [CompanyVATOrTinNo], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (7, 1, N'd1', N'c1', NULL, NULL, NULL, NULL, NULL, NULL, 4, CAST(0x0000A31500FA6299 AS DateTime), NULL, NULL, 1)
GO
SET IDENTITY_INSERT [dbo].[Dealer] OFF
GO
SET IDENTITY_INSERT [dbo].[GoldRates] ON 

GO
INSERT [dbo].[GoldRates] ([Id], [GoldCity], [URL]) VALUES (1, N'Delhi', N'http://www.indiagoldrate.com/gold-rate-in-delhi-today.htm@http://www.indiagoldrate.com/silver-rate-in-delhi-today.htm')
GO
INSERT [dbo].[GoldRates] ([Id], [GoldCity], [URL]) VALUES (2, N'Mumbai', N'http://www.indiagoldrate.com/gold-rate-in-mumbai-today.htm@http://www.indiagoldrate.com/silver-rate-in-mumbai-today.htm')
GO
INSERT [dbo].[GoldRates] ([Id], [GoldCity], [URL]) VALUES (3, N'Chennai', N'http://www.indiagoldrate.com/gold-rate-in-chennai-today.htm@http://www.indiagoldrate.com/silver-rate-in-chennai-today.htm')
GO
INSERT [dbo].[GoldRates] ([Id], [GoldCity], [URL]) VALUES (4, N'Kolkata', N'http://www.indiagoldrate.com/gold-rate-in-kolkata-today.htm@http://www.indiagoldrate.com/silver-rate-in-kolkata-today.htm')
GO
INSERT [dbo].[GoldRates] ([Id], [GoldCity], [URL]) VALUES (5, N'Hyderabad', N'http://www.indiagoldrate.com/gold-rate-in-hyderabad-today.htm@http://www.indiagoldrate.com/silver-rate-in-hyderabad-today.htm')
GO
SET IDENTITY_INSERT [dbo].[GoldRates] OFF
GO
SET IDENTITY_INSERT [dbo].[GoldRatesManual] ON 

GO
INSERT [dbo].[GoldRatesManual] ([Id], [InstanceId], [City], [GoldWeight], [GoldPrice], [SilverWeight], [SilverPrice], [CreatedDate]) VALUES (1, 1, N'Hyderabad', N'10g', N'21,541', N'10g', N'455', CAST(0x0000A30500000000 AS DateTime))
GO
SET IDENTITY_INSERT [dbo].[GoldRatesManual] OFF
GO
SET IDENTITY_INSERT [dbo].[Instance] ON 

GO
INSERT [dbo].[Instance] ([Id], [Name], [ParentInstance], [Address], [PIN], [Phone], [Mobile], [CreatedDate], [LicenseStartDate], [LicenseEndDate], [Status], [GoldCityId], [Domain]) VALUES (1, N'POOJA', NULL, N'AS RAO Nagar', NULL, NULL, NULL, CAST(0x0000A2F100000000 AS DateTime), CAST(0x4C380B00 AS Date), CAST(0xB9390B00 AS Date), NULL, 1, N'http://localhost:1101/')
GO
SET IDENTITY_INSERT [dbo].[Instance] OFF
GO
SET IDENTITY_INSERT [dbo].[Log4Net_Error] ON 

GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (2, CAST(0x0000A2F100EDFEB2 AS DateTime), N'22', N'ERROR', N'THSMVC.MvcApplication', N'App_Error', N'System.InvalidOperationException: The ViewData item that has the key ''Country'' is of type ''System.Int32'' but must be of type ''IEnumerable<SelectListItem>''.
   at System.Web.Mvc.Html.SelectExtensions.GetSelectData(HtmlHelper htmlHelper, String name)
   at System.Web.Mvc.Html.SelectExtensions.SelectInternal(HtmlHelper htmlHelper, String optionLabel, String name, IEnumerable`1 selectList, Boolean allowMultiple, IDictionary`2 htmlAttributes)
   at System.Web.Mvc.Html.SelectExtensions.DropDownListHelper(HtmlHelper htmlHelper, String expression, IEnumerable`1 selectList, String optionLabel, IDictionary`2 htmlAttributes)
   at System.Web.Mvc.Html.SelectExtensions.DropDownListFor[TModel,TProperty](HtmlHelper`1 htmlHelper, Expression`1 expression, IEnumerable`1 selectList, String optionLabel, IDictionary`2 htmlAttributes)
   at System.Web.Mvc.Html.SelectExtensions.DropDownListFor[TModel,TProperty](HtmlHelper`1 htmlHelper, Expression`1 expression, IEnumerable`1 selectList, String optionLabel, Object htmlAttributes)
   at ASP.views_admin_updateinstance_aspx.__Render__control1(HtmlTextWriter __w, Control parameterContainer) in d:\Projects\Sample\documents-export-2014-03-17\THSMVC\THSMVC\THSMVC\Views\Admin\UpdateInstance.aspx:line 173
   at System.Web.UI.Control.RenderChildrenInternal(HtmlTextWriter writer, ICollection children)
   at System.Web.UI.Control.RenderChildren(HtmlTextWriter writer)
   at System.Web.UI.Page.Render(HtmlTextWriter writer)
   at System.Web.Mvc.ViewPage.Render(HtmlTextWriter writer)
   at System.Web.UI.Control.RenderControlInternal(HtmlTextWriter writer, ControlAdapter adapter)
   at System.Web.UI.Control.RenderControl(HtmlTextWriter writer, ControlAdapter adapter)
   at System.Web.UI.Control.RenderControl(HtmlTextWriter writer)
   at System.Web.UI.Page.ProcessRequestMain(Boolean includeStagesBeforeAsyncPoint, Boolean includeStagesAfterAsyncPoint)', N'3')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (3, CAST(0x0000A30D011E940E AS DateTime), N'13', N'ERROR', N'THSMVC.MvcApplication', N'App_Error', N'System.Web.HttpException (0x80004005): A public action method ''JsonLotCollection'' was not found on controller ''THSMVC.Controllers.AdminController''.
   at System.Web.Mvc.Controller.HandleUnknownAction(String actionName)
   at System.Web.Mvc.Controller.ExecuteCore()
   at System.Web.Mvc.ControllerBase.Execute(RequestContext requestContext)
   at System.Web.Mvc.ControllerBase.System.Web.Mvc.IController.Execute(RequestContext requestContext)
   at System.Web.Mvc.MvcHandler.<>c__DisplayClass8.<BeginProcessRequest>b__4()
   at System.Web.Mvc.Async.AsyncResultWrapper.<>c__DisplayClass1.<MakeVoidDelegate>b__0()
   at System.Web.Mvc.Async.AsyncResultWrapper.<>c__DisplayClass8`1.<BeginSynchronous>b__7(IAsyncResult _)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResult`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncResultWrapper.End(IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.MvcHandler.EndProcessRequest(IAsyncResult asyncResult)
   at System.Web.Mvc.MvcHandler.System.Web.IHttpAsyncHandler.EndProcessRequest(IAsyncResult result)
   at System.Web.HttpApplication.CallHandlerExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (4, CAST(0x0000A30D011EB2A2 AS DateTime), N'13', N'ERROR', N'THSMVC.MvcApplication', N'App_Error', N'System.Web.HttpException (0x80004005): A public action method ''JsonLotCollection'' was not found on controller ''THSMVC.Controllers.AdminController''.
   at System.Web.Mvc.Controller.HandleUnknownAction(String actionName)
   at System.Web.Mvc.Controller.ExecuteCore()
   at System.Web.Mvc.ControllerBase.Execute(RequestContext requestContext)
   at System.Web.Mvc.ControllerBase.System.Web.Mvc.IController.Execute(RequestContext requestContext)
   at System.Web.Mvc.MvcHandler.<>c__DisplayClass8.<BeginProcessRequest>b__4()
   at System.Web.Mvc.Async.AsyncResultWrapper.<>c__DisplayClass1.<MakeVoidDelegate>b__0()
   at System.Web.Mvc.Async.AsyncResultWrapper.<>c__DisplayClass8`1.<BeginSynchronous>b__7(IAsyncResult _)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResult`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncResultWrapper.End(IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.MvcHandler.EndProcessRequest(IAsyncResult asyncResult)
   at System.Web.Mvc.MvcHandler.System.Web.IHttpAsyncHandler.EndProcessRequest(IAsyncResult result)
   at System.Web.HttpApplication.CallHandlerExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (7, CAST(0x0000A30F00DF5BB3 AS DateTime), N'5', N'ERROR', N'THSMVC.MvcApplication', N'App_Error', N'System.Web.HttpException (0x80004005): A public action method ''EditProductGroup'' was not found on controller ''THSMVC.Controllers.ProductGroupController''.
   at System.Web.Mvc.Controller.HandleUnknownAction(String actionName)
   at System.Web.Mvc.Controller.ExecuteCore()
   at System.Web.Mvc.ControllerBase.Execute(RequestContext requestContext)
   at System.Web.Mvc.ControllerBase.System.Web.Mvc.IController.Execute(RequestContext requestContext)
   at System.Web.Mvc.MvcHandler.<>c__DisplayClass8.<BeginProcessRequest>b__4()
   at System.Web.Mvc.Async.AsyncResultWrapper.<>c__DisplayClass1.<MakeVoidDelegate>b__0()
   at System.Web.Mvc.Async.AsyncResultWrapper.<>c__DisplayClass8`1.<BeginSynchronous>b__7(IAsyncResult _)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResult`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncResultWrapper.End(IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.MvcHandler.EndProcessRequest(IAsyncResult asyncResult)
   at System.Web.Mvc.MvcHandler.System.Web.IHttpAsyncHandler.EndProcessRequest(IAsyncResult result)
   at System.Web.HttpApplication.CallHandlerExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (8, CAST(0x0000A30F00DF6130 AS DateTime), N'12', N'ERROR', N'THSMVC.MvcApplication', N'App_Error', N'System.Web.HttpException (0x80004005): A public action method ''EditProductGroup'' was not found on controller ''THSMVC.Controllers.ProductGroupController''.
   at System.Web.Mvc.Controller.HandleUnknownAction(String actionName)
   at System.Web.Mvc.Controller.ExecuteCore()
   at System.Web.Mvc.ControllerBase.Execute(RequestContext requestContext)
   at System.Web.Mvc.ControllerBase.System.Web.Mvc.IController.Execute(RequestContext requestContext)
   at System.Web.Mvc.MvcHandler.<>c__DisplayClass8.<BeginProcessRequest>b__4()
   at System.Web.Mvc.Async.AsyncResultWrapper.<>c__DisplayClass1.<MakeVoidDelegate>b__0()
   at System.Web.Mvc.Async.AsyncResultWrapper.<>c__DisplayClass8`1.<BeginSynchronous>b__7(IAsyncResult _)
   at System.Web.Mvc.Async.AsyncResultWrapper.WrappedAsyncResult`1.End()
   at System.Web.Mvc.Async.AsyncResultWrapper.End[TResult](IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.Async.AsyncResultWrapper.End(IAsyncResult asyncResult, Object tag)
   at System.Web.Mvc.MvcHandler.EndProcessRequest(IAsyncResult asyncResult)
   at System.Web.Mvc.MvcHandler.System.Web.IHttpAsyncHandler.EndProcessRequest(IAsyncResult result)
   at System.Web.HttpApplication.CallHandlerExecutionStep.System.Web.HttpApplication.IExecutionStep.Execute()
   at System.Web.HttpApplication.ExecuteStep(IExecutionStep step, Boolean& completedSynchronously)', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (11, CAST(0x0000A3100133B4B5 AS DateTime), N'11', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonDealerCollection', N'System.ArgumentException: Instance property ''Dealer1'' is not defined for type ''THSMVC.Models.DealerModel''
   at System.Linq.Expressions.Expression.Property(Expression expression, String propertyName)
   at THSMVC.Models.Helpers.LinqExtensions.OrderBy[T](IQueryable`1 query, String sortColumn, String direction) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Models\Helpers\LinqExtensions.cs:line 25
   at THSMVC.Controllers.DealerController.JsonDealerCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\DealerController.cs:line 171', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (12, CAST(0x0000A3100133C882 AS DateTime), N'11', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonDealerCollection', N'System.ArgumentException: Instance property ''Dealer1'' is not defined for type ''THSMVC.Models.DealerModel''
   at System.Linq.Expressions.Expression.Property(Expression expression, String propertyName)
   at THSMVC.Models.Helpers.LinqExtensions.OrderBy[T](IQueryable`1 query, String sortColumn, String direction) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Models\Helpers\LinqExtensions.cs:line 25
   at THSMVC.Controllers.DealerController.JsonDealerCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\DealerController.cs:line 171', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (13, CAST(0x0000A3100133D90C AS DateTime), N'20', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonDealerCollection', N'System.ArgumentException: Instance property ''Dealer1'' is not defined for type ''THSMVC.Models.DealerModel''
   at System.Linq.Expressions.Expression.Property(Expression expression, String propertyName)
   at THSMVC.Models.Helpers.LinqExtensions.OrderBy[T](IQueryable`1 query, String sortColumn, String direction) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Models\Helpers\LinqExtensions.cs:line 25
   at THSMVC.Controllers.DealerController.JsonDealerCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\DealerController.cs:line 171', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (14, CAST(0x0000A3100133F30D AS DateTime), N'21', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonDealerCollection', N'System.ArgumentException: Instance property ''Dealer1'' is not defined for type ''THSMVC.Models.DealerModel''
   at System.Linq.Expressions.Expression.Property(Expression expression, String propertyName)
   at THSMVC.Models.Helpers.LinqExtensions.OrderBy[T](IQueryable`1 query, String sortColumn, String direction) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Models\Helpers\LinqExtensions.cs:line 25
   at THSMVC.Controllers.DealerController.JsonDealerCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\DealerController.cs:line 171', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (15, CAST(0x0000A31001342537 AS DateTime), N'21', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonDealerCollection', N'System.ArgumentException: Instance property ''Dealer1'' is not defined for type ''THSMVC.Models.DealerModel''
   at System.Linq.Expressions.Expression.Property(Expression expression, String propertyName)
   at THSMVC.Models.Helpers.LinqExtensions.OrderBy[T](IQueryable`1 query, String sortColumn, String direction) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Models\Helpers\LinqExtensions.cs:line 25
   at THSMVC.Controllers.DealerController.JsonDealerCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\DealerController.cs:line 171', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (16, CAST(0x0000A3100134CAEC AS DateTime), N'23', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonDealerCollection', N'System.NullReferenceException: Object reference not set to an instance of an object.
   at lambda_method(Closure , DealerModel )
   at System.Linq.Enumerable.WhereSelectArrayIterator`2.MoveNext()
   at System.Linq.Buffer`1..ctor(IEnumerable`1 source)
   at System.Linq.Enumerable.ToArray[TSource](IEnumerable`1 source)
   at THSMVC.Controllers.DealerController.JsonDealerCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\DealerController.cs:line 180', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (17, CAST(0x0000A3100134F0F8 AS DateTime), N'25', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonDealerCollection', N'System.NullReferenceException: Object reference not set to an instance of an object.
   at lambda_method(Closure , DealerModel )
   at System.Linq.Enumerable.WhereSelectArrayIterator`2.MoveNext()
   at System.Linq.Buffer`1..ctor(IEnumerable`1 source)
   at System.Linq.Enumerable.ToArray[TSource](IEnumerable`1 source)
   at THSMVC.Controllers.DealerController.JsonDealerCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\DealerController.cs:line 180', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (18, CAST(0x0000A31001352385 AS DateTime), N'24', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonDealerCollection', N'System.NullReferenceException: Object reference not set to an instance of an object.
   at lambda_method(Closure , DealerModel )
   at System.Linq.Enumerable.WhereSelectArrayIterator`2.MoveNext()
   at System.Linq.Buffer`1..ctor(IEnumerable`1 source)
   at System.Linq.Enumerable.ToArray[TSource](IEnumerable`1 source)
   at THSMVC.Controllers.DealerController.JsonDealerCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\DealerController.cs:line 180', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (19, CAST(0x0000A31001358797 AS DateTime), N'25', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonDealerCollection', N'System.NullReferenceException: Object reference not set to an instance of an object.
   at lambda_method(Closure , DealerModel )
   at System.Linq.Enumerable.WhereSelectArrayIterator`2.MoveNext()
   at System.Linq.Buffer`1..ctor(IEnumerable`1 source)
   at System.Linq.Enumerable.ToArray[TSource](IEnumerable`1 source)
   at THSMVC.Controllers.DealerController.JsonDealerCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\DealerController.cs:line 180', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (20, CAST(0x0000A31500CE587C AS DateTime), N'13', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonInstaneCollection', N'System.Data.EntityCommandExecutionException: An error occurred while reading from the store provider''s data reader. See the inner exception for details. ---> System.Data.SqlClient.SqlException: Conversion failed when converting the varchar value ''<a href="#" onclick="EditLotAssignment('' to data type int.
   at System.Data.SqlClient.SqlConnection.OnError(SqlException exception, Boolean breakConnection, Action`1 wrapCloseInAction)
   at System.Data.SqlClient.SqlInternalConnection.OnError(SqlException exception, Boolean breakConnection, Action`1 wrapCloseInAction)
   at System.Data.SqlClient.TdsParser.ThrowExceptionAndWarning(TdsParserStateObject stateObj, Boolean callerHasConnectionLock, Boolean asyncClose)
   at System.Data.SqlClient.TdsParser.TryRun(RunBehavior runBehavior, SqlCommand cmdHandler, SqlDataReader dataStream, BulkCopySimpleResultSet bulkCopyHandler, TdsParserStateObject stateObj, Boolean& dataReady)
   at System.Data.SqlClient.SqlDataReader.TryHasMoreRows(Boolean& moreRows)
   at System.Data.SqlClient.SqlDataReader.TryReadInternal(Boolean setTimeout, Boolean& more)
   at System.Data.SqlClient.SqlDataReader.Read()
   at System.Data.Common.Internal.Materialization.Shaper`1.StoreRead()
   --- End of inner exception stack trace ---
   at System.Data.Common.Internal.Materialization.Shaper`1.StoreRead()
   at System.Data.Common.Internal.Materialization.Shaper`1.SimpleEnumerator.MoveNext()
   at System.Collections.Generic.List`1..ctor(IEnumerable`1 collection)
   at System.Linq.Enumerable.ToList[TSource](IEnumerable`1 source)
   at THSMVC.App_Code.LotLogic.GetAssignedLots() in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Classes\LotLogic.cs:line 139
   at THSMVC.Controllers.LotController.GetAssignedLots() in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\LotController.cs:line 293
   at THSMVC.Controllers.LotController.JsonAssignedLotCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\LotController.cs:line 162', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (21, CAST(0x0000A31500CE72A7 AS DateTime), N'13', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonInstaneCollection', N'System.Data.EntityCommandExecutionException: An error occurred while reading from the store provider''s data reader. See the inner exception for details. ---> System.Data.SqlClient.SqlException: Conversion failed when converting the varchar value ''<a href="#" onclick="EditLotAssignment('' to data type int.
   at System.Data.SqlClient.SqlConnection.OnError(SqlException exception, Boolean breakConnection, Action`1 wrapCloseInAction)
   at System.Data.SqlClient.SqlInternalConnection.OnError(SqlException exception, Boolean breakConnection, Action`1 wrapCloseInAction)
   at System.Data.SqlClient.TdsParser.ThrowExceptionAndWarning(TdsParserStateObject stateObj, Boolean callerHasConnectionLock, Boolean asyncClose)
   at System.Data.SqlClient.TdsParser.TryRun(RunBehavior runBehavior, SqlCommand cmdHandler, SqlDataReader dataStream, BulkCopySimpleResultSet bulkCopyHandler, TdsParserStateObject stateObj, Boolean& dataReady)
   at System.Data.SqlClient.SqlDataReader.TryHasMoreRows(Boolean& moreRows)
   at System.Data.SqlClient.SqlDataReader.TryReadInternal(Boolean setTimeout, Boolean& more)
   at System.Data.SqlClient.SqlDataReader.Read()
   at System.Data.Common.Internal.Materialization.Shaper`1.StoreRead()
   --- End of inner exception stack trace ---
   at System.Data.Common.Internal.Materialization.Shaper`1.StoreRead()
   at System.Data.Common.Internal.Materialization.Shaper`1.SimpleEnumerator.MoveNext()
   at System.Collections.Generic.List`1..ctor(IEnumerable`1 collection)
   at System.Linq.Enumerable.ToList[TSource](IEnumerable`1 source)
   at THSMVC.App_Code.LotLogic.GetAssignedLots() in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Classes\LotLogic.cs:line 139
   at THSMVC.Controllers.LotController.GetAssignedLots() in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\LotController.cs:line 293
   at THSMVC.Controllers.LotController.JsonAssignedLotCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\LotController.cs:line 162', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (24, CAST(0x0000A315010EB0DF AS DateTime), N'19', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonRoleCollection', N'System.ArgumentException: Instance property ''Role1'' is not defined for type ''THSMVC.Models.RoleModel''
   at System.Linq.Expressions.Expression.Property(Expression expression, String propertyName)
   at THSMVC.Models.Helpers.LinqExtensions.OrderBy[T](IQueryable`1 query, String sortColumn, String direction) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Models\Helpers\LinqExtensions.cs:line 25
   at THSMVC.Controllers.RoleController.JsonRoleCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\RoleController.cs:line 152', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (25, CAST(0x0000A315010EEF35 AS DateTime), N'39', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonRoleCollection', N'System.ArgumentException: Instance property ''Role1'' is not defined for type ''THSMVC.Models.RoleModel''
   at System.Linq.Expressions.Expression.Property(Expression expression, String propertyName)
   at THSMVC.Models.Helpers.LinqExtensions.OrderBy[T](IQueryable`1 query, String sortColumn, String direction) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Models\Helpers\LinqExtensions.cs:line 25
   at THSMVC.Controllers.RoleController.JsonRoleCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\RoleController.cs:line 152', N'4')
GO
INSERT [dbo].[Log4Net_Error] ([Id], [Date], [Thread], [Level], [Logger], [Message], [Exception], [UserID]) VALUES (26, CAST(0x0000A315010F0BEF AS DateTime), N'57', N'ERROR', N'THSMVC.Services.Logging.Log4Net.Log4NetLogger', N'JsonRoleCollection', N'System.ArgumentException: Instance property ''Role1'' is not defined for type ''THSMVC.Models.RoleModel''
   at System.Linq.Expressions.Expression.Property(Expression expression, String propertyName)
   at THSMVC.Models.Helpers.LinqExtensions.OrderBy[T](IQueryable`1 query, String sortColumn, String direction) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Models\Helpers\LinqExtensions.cs:line 25
   at THSMVC.Controllers.RoleController.JsonRoleCollection(GridSettings grid) in d:\Projects\Sample\PJ\JEWELLERY\THSMVC\Controllers\RoleController.cs:line 152', N'4')
GO
SET IDENTITY_INSERT [dbo].[Log4Net_Error] OFF
GO
SET IDENTITY_INSERT [dbo].[Lot] ON 

GO
INSERT [dbo].[Lot] ([LotId], [InstanceId], [LotName], [Weight], [NoOfPieces], [ProductGroupId], [DealerId], [IsMRP], [MRP], [DiffAllowed]) VALUES (1, 1, N'Lot Test', CAST(100.00 AS Decimal(18, 2)), 10, 12, 0, NULL, NULL, NULL)
GO
INSERT [dbo].[Lot] ([LotId], [InstanceId], [LotName], [Weight], [NoOfPieces], [ProductGroupId], [DealerId], [IsMRP], [MRP], [DiffAllowed]) VALUES (2, 1, N'L2', CAST(10.00 AS Decimal(18, 2)), 10, 12, 0, NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[Lot] OFF
GO
SET IDENTITY_INSERT [dbo].[LotStatus] ON 

GO
INSERT [dbo].[LotStatus] ([StatusId], [EnumValue]) VALUES (1, N'New')
GO
INSERT [dbo].[LotStatus] ([StatusId], [EnumValue]) VALUES (2, N'Assigned')
GO
INSERT [dbo].[LotStatus] ([StatusId], [EnumValue]) VALUES (3, N'In Process')
GO
INSERT [dbo].[LotStatus] ([StatusId], [EnumValue]) VALUES (4, N'Sumitted')
GO
INSERT [dbo].[LotStatus] ([StatusId], [EnumValue]) VALUES (5, N'Closed')
GO
SET IDENTITY_INSERT [dbo].[LotStatus] OFF
GO
SET IDENTITY_INSERT [dbo].[Menu] ON 

GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (1, NULL, NULL, N'Home', N'Welcome', N'Admin', NULL, 0, 0, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (2, NULL, NULL, N'Masters', NULL, NULL, NULL, 1, 0, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (4, NULL, 1, N'Change Password', N'ChangePwd', N'Shared', 2, 0, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (5, NULL, NULL, N'Clients', N'ManageInstance', N'Admin', NULL, 2, 0, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (6, NULL, 5, N'Manage Instance', N'ManageInstance', N'Admin', 3, 0, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (7, NULL, 5, N'Create Instance', N'CreateInstance', N'Admin', 3, 1, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (11, NULL, 5, N'Register Admin', N'RegisterAdmin', N'Admin', 3, 2, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (12, 1, NULL, N'Home', N'Welcome', N'Admin', NULL, 0, 0, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (39, NULL, 2, N'Error Logs', N'ErrorLogs', N'Admin', 4, 18, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (40, NULL, 2, N'Site Logs', N'SiteLog', N'Admin', 4, 19, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (154, 1, 12, N'Change Password', N'ChangePwd', N'Shared', 2, 0, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (155, 1, NULL, N'Lot', N'LotMaster', N'Lot', NULL, 0, 0, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (156, 1, 12, N'Manage Roles', N'ManageRoles', N'Admin', 2, 1, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (157, 1, 155, N'Lot', N'LotMaster', N'Lot', 7, 0, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (158, 1, NULL, N'Masters', N'ProductGroupMaster', N'ProductGroup', NULL, 0, 0, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (159, 1, 158, N'Product Group', N'ProductGroupMaster', N'ProductGroup', 8, 0, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (160, 1, 158, N'Dealer', N'DealerMaster', N'Dealer', 8, 1, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (161, 1, 158, N'Product Category', N'ProductCategoryMaster', N'ProductCategory', 8, 2, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (162, 1, 158, N'Product', N'ProductMaster', N'Product', 8, 3, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (163, 1, 158, N'User', N'UserMaster', N'User', 8, 4, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (164, 1, 155, N'Assign Lot', N'AssignLot', N'Lot', 7, 1, 1, NULL)
GO
INSERT [dbo].[Menu] ([Id], [InstanceId], [ParentId], [Name], [Action], [Controller], [GroupId], [Order], [Level], [Status]) VALUES (165, 1, 158, N'Roles', N'RoleMaster', N'Role', 8, 5, 1, NULL)
GO
SET IDENTITY_INSERT [dbo].[Menu] OFF
GO
SET IDENTITY_INSERT [dbo].[MenuGroup] ON 

GO
INSERT [dbo].[MenuGroup] ([Id], [InstanceId], [GroupName], [GroupShortName], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (2, NULL, N'Account', N'Acct', 1, CAST(0x00009FEE00000000 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[MenuGroup] ([Id], [InstanceId], [GroupName], [GroupShortName], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (3, NULL, N'Manage Clients', N'Client', 1, CAST(0x00009FF000000000 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[MenuGroup] ([Id], [InstanceId], [GroupName], [GroupShortName], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (4, NULL, N'Master Pages', N'Masters', 1, CAST(0x00009FF100000000 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[MenuGroup] ([Id], [InstanceId], [GroupName], [GroupShortName], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (6, NULL, N'Manage Menus', N'Menu', 1, CAST(0x0000A01F00000000 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[MenuGroup] ([Id], [InstanceId], [GroupName], [GroupShortName], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (7, 1, N'Manage Lot', N'Lot', 1, CAST(0x0000A18A00000000 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[MenuGroup] ([Id], [InstanceId], [GroupName], [GroupShortName], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (8, 1, N'Masters', N'Masters', 1, CAST(0x0000A31300000000 AS DateTime), NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[MenuGroup] OFF
GO
SET IDENTITY_INSERT [dbo].[MenuRight] ON 

GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (1, N'Change', N'Change Password', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (2, N'Create', N'Authorized to Create User', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (3, N'Update', N'Authorized to Update User', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (4, N'Delete', N'Delete', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (5, N'Create', N'Authorized to Create Test', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (6, N'Update', N'Authorized to Update Test', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (7, N'Manage', N'Authorized to Manage Test', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (8, N'Delete', N'Authorized to Delete Test', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (9, N'Assign', N'Authorized to Assign Test', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (10, N'Preview', N'Authorized to Preview Test', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (11, N'Create', N'Authorized to Create Notice', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (12, N'Delete', N'Authorized to Delete Notice', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (13, N'Update', N'Authorized to Update Notice', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (14, N'Create', N'Authorized to Create Test Category', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (15, N'Update', N'Authorized to Update Test Category', NULL)
GO
INSERT [dbo].[MenuRight] ([Id], [MenuRight], [MenuRightDescription], [Status]) VALUES (16, N'Delete', N'Authorized to Delete Test Category', NULL)
GO
SET IDENTITY_INSERT [dbo].[MenuRight] OFF
GO
SET IDENTITY_INSERT [dbo].[Product] ON 

GO
INSERT [dbo].[Product] ([Id], [InstanceId], [ProductName], [ShortForm], [ValueAddedByPerc], [ValueAddedFixed], [MakingChargesPerGram], [MakingChargesFixed], [IsStone], [IsWeightless], [ProductCategoryId], [ProductGroupId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (1, 1, N'sfs1', NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 4, CAST(0x0000A31100D04409 AS DateTime), 4, CAST(0x0000A31100D07489 AS DateTime), 1)
GO
INSERT [dbo].[Product] ([Id], [InstanceId], [ProductName], [ShortForm], [ValueAddedByPerc], [ValueAddedFixed], [MakingChargesPerGram], [MakingChargesFixed], [IsStone], [IsWeightless], [ProductCategoryId], [ProductGroupId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (2, 1, N'pn', N'sf', CAST(1.000 AS Decimal(18, 3)), CAST(10.000 AS Decimal(18, 3)), CAST(200.000 AS Decimal(18, 3)), CAST(100.000 AS Decimal(18, 3)), 1, 1, 3, 12, 4, CAST(0x0000A31100E33330 AS DateTime), 4, CAST(0x0000A31100E3924B AS DateTime), 1)
GO
SET IDENTITY_INSERT [dbo].[Product] OFF
GO
SET IDENTITY_INSERT [dbo].[ProductCategory] ON 

GO
INSERT [dbo].[ProductCategory] ([Id], [InstanceId], [ProductCategory], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (1, 1, N'cat1u', 4, CAST(0x0000A31100CBF44A AS DateTime), 4, CAST(0x0000A31100CBFC41 AS DateTime), 1)
GO
INSERT [dbo].[ProductCategory] ([Id], [InstanceId], [ProductCategory], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (2, 1, N'cat2', 4, CAST(0x0000A31100CC0813 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductCategory] ([Id], [InstanceId], [ProductCategory], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (3, 1, N'cat1', 4, CAST(0x0000A31100E31E2A AS DateTime), NULL, NULL, 1)
GO
SET IDENTITY_INSERT [dbo].[ProductCategory] OFF
GO
SET IDENTITY_INSERT [dbo].[ProductGroup] ON 

GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (1, 1, N'Test', 1, CAST(0x0000A30800000000 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (2, 1, N'Gold', 4, CAST(0x0000A30F00F152E1 AS DateTime), 4, CAST(0x0000A30F00F78C31 AS DateTime), 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (3, 1, N'Silver', 4, CAST(0x0000A30F00F196A5 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (4, 1, N'1234', 4, CAST(0x0000A30F00F1F3DF AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (5, 1, N'3445', 4, CAST(0x0000A30F00F20E42 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (6, 1, N'sfds', 4, CAST(0x0000A30F00F225A7 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (7, 1, N'sdfsdf', 4, CAST(0x0000A30F00F25A99 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (8, 1, N'9999', 4, CAST(0x0000A30F00F28AB1 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (9, 1, N'8989', 4, CAST(0x0000A30F00F34B4E AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (10, 1, N'sdf', 4, CAST(0x0000A30F00F7955D AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (11, 1, N'dfg', 4, CAST(0x0000A30F00F85960 AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (12, 1, N'Gold', 4, CAST(0x0000A310013EE0EF AS DateTime), 4, CAST(0x0000A310013EEFF2 AS DateTime), NULL)
GO
INSERT [dbo].[ProductGroup] ([Id], [InstanceId], [ProductGroup], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (13, 1, N'Silver', 4, CAST(0x0000A310013EE865 AS DateTime), NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[ProductGroup] OFF
GO
SET IDENTITY_INSERT [dbo].[Role] ON 

GO
INSERT [dbo].[Role] ([Id], [InstanceId], [Role], [RoleDesc], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (1, 1, N'Administrator', N'Admin', 3, CAST(0x00009FF20108BE1F AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[Role] ([Id], [InstanceId], [Role], [RoleDesc], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (2, 1, N'Sales Person', NULL, 4, CAST(0x0000A315010F3A36 AS DateTime), 4, CAST(0x0000A315010FAE40 AS DateTime), NULL)
GO
SET IDENTITY_INSERT [dbo].[Role] OFF
GO
SET IDENTITY_INSERT [dbo].[RoleMenu] ON 

GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (217, 1, 1, 12, 3, CAST(0x0000A2F100000000 AS DateTime), NULL, NULL, 0)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (218, 1, 1, 154, 3, CAST(0x0000A2F100000000 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (219, 1, 1, 156, 3, CAST(0x0000A2F700000000 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (220, 1, 1, 157, 4, CAST(0x0000A2F700C184FE AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (221, 1, 1, 155, 4, CAST(0x0000A2F700C18510 AS DateTime), NULL, NULL, 0)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (222, 1, 1, 159, 4, CAST(0x0000A30E013F7073 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (223, 1, 1, 158, 4, CAST(0x0000A30E013F7081 AS DateTime), NULL, NULL, 0)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (224, 1, 1, 160, 4, CAST(0x0000A310013000B9 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (225, 1, 1, 161, 4, CAST(0x0000A31100CBE8F3 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (226, 1, 1, 162, 4, CAST(0x0000A31100D0304E AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (227, 1, 1, 163, 4, CAST(0x0000A311010155AE AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (228, 1, 1, 164, 4, CAST(0x0000A3130093970A AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (229, 1, 1, 165, 4, CAST(0x0000A315010EAC8E AS DateTime), NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[RoleMenu] OFF
GO
SET IDENTITY_INSERT [dbo].[SiteLog] ON 

GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (1, CAST(0x0000A2F100EBAABE AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (2, CAST(0x0000A2F100EBBEDB AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (3, CAST(0x0000A2F100EBC417 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (4, CAST(0x0000A2F100EBC44E AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (5, CAST(0x0000A2F100EBD2A4 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (6, CAST(0x0000A2F100EBD483 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (7, CAST(0x0000A2F100EBDA35 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (8, CAST(0x0000A2F100EBDA4D AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/1?Id=Home', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (9, CAST(0x0000A2F100EBDA7F AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=1', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (10, CAST(0x0000A2F100EC0C9F AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=1', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (11, CAST(0x0000A2F100EC190E AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=1', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (12, CAST(0x0000A2F100EC1AC5 AS DateTime), N'ChangePwd', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Shared/ChangePwd/Change Password?MenuId=4', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (13, CAST(0x0000A2F100EC1EEA AS DateTime), N'EmptyContent', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (14, CAST(0x0000A2F100EC2134 AS DateTime), N'CreateMenu', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/CreateMenu/Create Menu?MenuId=32', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (15, CAST(0x0000A2F100EC76C8 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (16, CAST(0x0000A2F100EC7CDB AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (17, CAST(0x0000A2F100EC8237 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (18, CAST(0x0000A2F100EC8265 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/1?Id=Home', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (19, CAST(0x0000A2F100EC829A AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=1', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (20, CAST(0x0000A2F100EC839C AS DateTime), N'EmptyContent', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (21, CAST(0x0000A2F100EC8751 AS DateTime), N'CreateMenu', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/CreateMenu/Create Menu?MenuId=32', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (22, CAST(0x0000A2F100ECF51F AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (23, CAST(0x0000A2F100ECFAA6 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (24, CAST(0x0000A2F100ECFAAB AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/1?Id=Home', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (25, CAST(0x0000A2F100ECFEF1 AS DateTime), N'ErrorLogs', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ErrorLogs/Error Logs?MenuId=39', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (26, CAST(0x0000A2F100ED0077 AS DateTime), N'SiteLog', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/SiteLog/Site Logs?MenuId=40', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (27, CAST(0x0000A2F100ED02ED AS DateTime), N'ManageInstance', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageInstance/Clients?MenuId=5', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (28, CAST(0x0000A2F100ED02F6 AS DateTime), N'JsonInstaneCollection', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (29, CAST(0x0000A2F100ED2EAB AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (30, CAST(0x0000A2F100ED2EB1 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (31, CAST(0x0000A2F100ED2FFB AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (32, CAST(0x0000A2F100ED35DE AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (33, CAST(0x0000A2F100ED35E8 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/1?Id=Home', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (34, CAST(0x0000A2F100ED383C AS DateTime), N'ManageInstance', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageInstance/Clients?MenuId=5', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (35, CAST(0x0000A2F100ED55D6 AS DateTime), N'ManageInstance', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageInstance/Clients?MenuId=5', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (36, CAST(0x0000A2F100ED56DF AS DateTime), N'JsonInstaneCollection', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (37, CAST(0x0000A2F100ED703D AS DateTime), N'JsonInstaneCollection', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (38, CAST(0x0000A2F100EDA911 AS DateTime), N'JsonInstaneCollection', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (39, CAST(0x0000A2F100EDAE05 AS DateTime), N'JsonInstaneCollection', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (40, CAST(0x0000A2F100EDE139 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (41, CAST(0x0000A2F100EDE5C2 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (42, CAST(0x0000A2F100EDECD5 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (43, CAST(0x0000A2F100EDED08 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/1?Id=Home', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (44, CAST(0x0000A2F100EDED3B AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=1', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (45, CAST(0x0000A2F100EDEF71 AS DateTime), N'ManageInstance', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageInstance/Clients?MenuId=5', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (46, CAST(0x0000A2F100EDEF80 AS DateTime), N'JsonInstaneCollection', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (47, CAST(0x0000A2F100EDFA0F AS DateTime), N'UpdateInstance', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (48, CAST(0x0000A2F100EE1FA2 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (49, CAST(0x0000A2F100EE220B AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (50, CAST(0x0000A2F100EE2214 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (51, CAST(0x0000A2F100EE238E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (52, CAST(0x0000A2F100EE28E0 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (53, CAST(0x0000A2F100EE292F AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/1?Id=Home', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (54, CAST(0x0000A2F100EE2AD5 AS DateTime), N'ManageInstance', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageInstance/Clients?MenuId=5', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (55, CAST(0x0000A2F100EE2BF0 AS DateTime), N'JsonInstaneCollection', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (56, CAST(0x0000A2F100EE30E9 AS DateTime), N'UpdateInstance', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (57, CAST(0x0000A2F100EE4A6A AS DateTime), N'RegisterAdmin', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/RegisterAdmin/Register Admin?MenuId=11', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (58, CAST(0x0000A2F100EE5CC0 AS DateTime), N'EmptyContent', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (59, CAST(0x0000A2F100EE5F20 AS DateTime), N'ErrorLogs', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ErrorLogs/Error Logs?MenuId=39', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (60, CAST(0x0000A2F100EE615F AS DateTime), N'SiteLog', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/SiteLog/Site Logs?MenuId=40', N'::1', N'3')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (61, CAST(0x0000A2F100EEA421 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (62, CAST(0x0000A2F100EEA573 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (63, CAST(0x0000A2F100EEAADA AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (64, CAST(0x0000A2F100EEAAE0 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (65, CAST(0x0000A2F100EEF57D AS DateTime), N'UnAuthorized', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (66, CAST(0x0000A2F100F088C4 AS DateTime), N'ChangePwd', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Shared/ChangePwd/Change Password?MenuId=154', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (67, CAST(0x0000A30D011E6B7A AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (68, CAST(0x0000A30D011E7881 AS DateTime), N'GetGoldRate', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (69, CAST(0x0000A30D011E89DF AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (70, CAST(0x0000A30D011E8F3E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (71, CAST(0x0000A30D011E8F87 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (72, CAST(0x0000A30D011E8FE5 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (73, CAST(0x0000A30D011E9335 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (74, CAST(0x0000A30D011EB28F AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (75, CAST(0x0000A30E013F5306 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (76, CAST(0x0000A30E013F5B67 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (77, CAST(0x0000A30E013F62CE AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (78, CAST(0x0000A30E013F631C AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (79, CAST(0x0000A30E013F639C AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (80, CAST(0x0000A30E013F6B2A AS DateTime), N'ManageRoles', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageRoles/Manage Roles?MenuId=156', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (81, CAST(0x0000A30E013F6C91 AS DateTime), N'GetMenuItemsByRole', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (82, CAST(0x0000A30E013F7038 AS DateTime), N'AssignRemoveMenuItems', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (83, CAST(0x0000A30E013F734A AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (84, CAST(0x0000A30E013F75AE AS DateTime), N'JsonProductGroupCollection', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (85, CAST(0x0000A30E013F9D3C AS DateTime), N'JsonProductGroupCollection', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (86, CAST(0x0000A30E0140B38F AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (87, CAST(0x0000A30E0140B85F AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (88, CAST(0x0000A30E0140BDE7 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (89, CAST(0x0000A30E0140BE09 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (90, CAST(0x0000A30E0140BE61 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (91, CAST(0x0000A30E0140C41C AS DateTime), N'JsonProductGroupCollection', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (92, CAST(0x0000A30E014547A1 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (93, CAST(0x0000A30E0145504B AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (94, CAST(0x0000A30E014554E5 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (95, CAST(0x0000A30E01455505 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (96, CAST(0x0000A30E01455549 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (97, CAST(0x0000A30E01455790 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (98, CAST(0x0000A30E0145596E AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (99, CAST(0x0000A30E0145A30D AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (100, CAST(0x0000A30E0145A4D9 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (101, CAST(0x0000A30E01460565 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (102, CAST(0x0000A30E01460A28 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (103, CAST(0x0000A30E01460E7F AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (104, CAST(0x0000A30E01460E9D AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (105, CAST(0x0000A30E01460EE0 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (106, CAST(0x0000A30E014610EF AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (107, CAST(0x0000A30E014612F2 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (108, CAST(0x0000A30E01463B70 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (109, CAST(0x0000A30E01463D31 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (110, CAST(0x0000A30E01480A3C AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (111, CAST(0x0000A30E01483F01 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (112, CAST(0x0000A30E01484B60 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (113, CAST(0x0000A30E0148BDF6 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (114, CAST(0x0000A30E0148BFB7 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (115, CAST(0x0000A30E0148BFBF AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (116, CAST(0x0000A30E0148C0A0 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (117, CAST(0x0000A30E0148C4CC AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (118, CAST(0x0000A30E0148C4D5 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (119, CAST(0x0000A30E0148C6C5 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (120, CAST(0x0000A30E0148C8ED AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (121, CAST(0x0000A30E0148F9E1 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (122, CAST(0x0000A30E0148FC0F AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (123, CAST(0x0000A30E014945BC AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (124, CAST(0x0000A30E014948A5 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (125, CAST(0x0000A30E01495BFD AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (126, CAST(0x0000A30E01495E00 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (127, CAST(0x0000A30E0149BAEA AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (128, CAST(0x0000A30E0149BDCF AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (129, CAST(0x0000A30E014A5D97 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (130, CAST(0x0000A30E014A6865 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (131, CAST(0x0000A30E014A7F05 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (132, CAST(0x0000A30E014A8827 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (133, CAST(0x0000A30E014A9062 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (134, CAST(0x0000A30E014A9398 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (135, CAST(0x0000A30E014A93AA AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (136, CAST(0x0000A30E014A9595 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (137, CAST(0x0000A30E014A984D AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (138, CAST(0x0000A30E014AA86E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (139, CAST(0x0000A30E014AB024 AS DateTime), N'TimeoutExpired', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (140, CAST(0x0000A30E014AB04B AS DateTime), N'SessionExpire', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (141, CAST(0x0000A30E014AB2F6 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (142, CAST(0x0000A30E014AB6D5 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (143, CAST(0x0000A30E014AB6DE AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (144, CAST(0x0000A30E014AD324 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (145, CAST(0x0000A30E014AE17B AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (146, CAST(0x0000A30E014AE8E7 AS DateTime), N'SessionExpire', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (147, CAST(0x0000A30E014D80B2 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (148, CAST(0x0000A30E014D80BE AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (149, CAST(0x0000A30E014D82ED AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (150, CAST(0x0000A30E014D99ED AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (151, CAST(0x0000A30E014D9D18 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (152, CAST(0x0000A30E014DC2CD AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (153, CAST(0x0000A30E014DC49C AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (154, CAST(0x0000A30E014DC761 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (155, CAST(0x0000A30E014DD191 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (156, CAST(0x0000A30E014E8D08 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (157, CAST(0x0000A30E014E9121 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (158, CAST(0x0000A30E014E913F AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (159, CAST(0x0000A30E014E9188 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (160, CAST(0x0000A30E014E92FB AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (161, CAST(0x0000A30E014E9581 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (162, CAST(0x0000A30E014EA154 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (163, CAST(0x0000A30E014F17B7 AS DateTime), N'TimeoutExpired', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (164, CAST(0x0000A30E014F17E0 AS DateTime), N'SessionExpire', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (165, CAST(0x0000A30E014F1A56 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (166, CAST(0x0000A30E014F1E8B AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (167, CAST(0x0000A30E014F1E9A AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (168, CAST(0x0000A30E014F74F3 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (169, CAST(0x0000A30E014F76F7 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (170, CAST(0x0000A30E015043CD AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (171, CAST(0x0000A30E01504703 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (172, CAST(0x0000A30E01504894 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (173, CAST(0x0000A30F00DEA4E0 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (174, CAST(0x0000A30F00DEB4A8 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (175, CAST(0x0000A30F00DEBA83 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (176, CAST(0x0000A30F00DEBAD4 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (177, CAST(0x0000A30F00DEBB1F AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (178, CAST(0x0000A30F00DEBE48 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (179, CAST(0x0000A30F00DEE528 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (180, CAST(0x0000A30F00DEEAB0 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (181, CAST(0x0000A30F00DEF088 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (182, CAST(0x0000A30F00DEF0AE AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (183, CAST(0x0000A30F00DEF0E5 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (184, CAST(0x0000A30F00DEF31F AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (185, CAST(0x0000A30F00DEF529 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (186, CAST(0x0000A30F00DF4864 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (187, CAST(0x0000A30F00DF4EAC AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (188, CAST(0x0000A30F00DF5558 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (189, CAST(0x0000A30F00DF5575 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (190, CAST(0x0000A30F00DF55C0 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (191, CAST(0x0000A30F00DF5951 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (192, CAST(0x0000A30F00DF7EAE AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (193, CAST(0x0000A30F00DF83FB AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (194, CAST(0x0000A30F00DF88F7 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (195, CAST(0x0000A30F00DF8919 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (196, CAST(0x0000A30F00DF8950 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (197, CAST(0x0000A30F00DF8B54 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (198, CAST(0x0000A30F00DF8DE0 AS DateTime), N'EditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (199, CAST(0x0000A30F00E15B41 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (200, CAST(0x0000A30F00E15FC0 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (201, CAST(0x0000A30F00E16485 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (202, CAST(0x0000A30F00E164A5 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (203, CAST(0x0000A30F00E164E3 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (204, CAST(0x0000A30F00E166A7 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (205, CAST(0x0000A30F00E16823 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (206, CAST(0x0000A30F00F10EF2 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (207, CAST(0x0000A30F00F14570 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (208, CAST(0x0000A30F00F14A21 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (209, CAST(0x0000A30F00F14A3B AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (210, CAST(0x0000A30F00F14A72 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (211, CAST(0x0000A30F00F14C8D AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (212, CAST(0x0000A30F00F14F80 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (213, CAST(0x0000A30F00F152DE AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (214, CAST(0x0000A30F00F191BD AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (215, CAST(0x0000A30F00F196A5 AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (216, CAST(0x0000A30F00F19EF5 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (217, CAST(0x0000A30F00F1EEBF AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (218, CAST(0x0000A30F00F1F065 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (219, CAST(0x0000A30F00F1F3DF AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (220, CAST(0x0000A30F00F207FE AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (221, CAST(0x0000A30F00F209D0 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (222, CAST(0x0000A30F00F20B9A AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (223, CAST(0x0000A30F00F20E42 AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (224, CAST(0x0000A30F00F225A7 AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (225, CAST(0x0000A30F00F25352 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (226, CAST(0x0000A30F00F2588C AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (227, CAST(0x0000A30F00F25A98 AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (228, CAST(0x0000A30F00F28452 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (229, CAST(0x0000A30F00F2877D AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (230, CAST(0x0000A30F00F28AB0 AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (231, CAST(0x0000A30F00F2C737 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (232, CAST(0x0000A30F00F3185F AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (233, CAST(0x0000A30F00F31B03 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (234, CAST(0x0000A30F00F3410C AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (235, CAST(0x0000A30F00F345AC AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (236, CAST(0x0000A30F00F34B4E AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (237, CAST(0x0000A30F00F486AE AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (238, CAST(0x0000A30F00F48BBE AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (239, CAST(0x0000A30F00F49057 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (240, CAST(0x0000A30F00F4907D AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (241, CAST(0x0000A30F00F490B7 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (242, CAST(0x0000A30F00F49BE0 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (243, CAST(0x0000A30F00F4A3FD AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (244, CAST(0x0000A30F00F5993C AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (245, CAST(0x0000A30F00F5A04E AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (246, CAST(0x0000A30F00F5B277 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (247, CAST(0x0000A30F00F5BB62 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (248, CAST(0x0000A30F00F5BF8B AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (249, CAST(0x0000A30F00F5FF52 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (250, CAST(0x0000A30F00F60432 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (251, CAST(0x0000A30F00F60A16 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (252, CAST(0x0000A30F00F60A3A AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (253, CAST(0x0000A30F00F60A73 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (254, CAST(0x0000A30F00F60DE4 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (255, CAST(0x0000A30F00F61286 AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (256, CAST(0x0000A30F00F6252C AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (257, CAST(0x0000A30F00F628F3 AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (258, CAST(0x0000A30F00F65E61 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (259, CAST(0x0000A30F00F66224 AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (260, CAST(0x0000A30F00F6935D AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (261, CAST(0x0000A30F00F697D2 AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (262, CAST(0x0000A30F00F6B11F AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (263, CAST(0x0000A30F00F6C5FE AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Product Group?MenuId=159', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (264, CAST(0x0000A30F00F6C786 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (265, CAST(0x0000A30F00F717B3 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (266, CAST(0x0000A30F00F717B9 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (267, CAST(0x0000A30F00F726A1 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (268, CAST(0x0000A30F00F72881 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (269, CAST(0x0000A30F00F72C60 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (270, CAST(0x0000A30F00F72C68 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (271, CAST(0x0000A30F00F73124 AS DateTime), N'EditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (272, CAST(0x0000A30F00F7361B AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (273, CAST(0x0000A30F00F73F5F AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (274, CAST(0x0000A30F00F7735A AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (275, CAST(0x0000A30F00F777F7 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (276, CAST(0x0000A30F00F77C29 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (277, CAST(0x0000A30F00F77C47 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (278, CAST(0x0000A30F00F77C7E AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (279, CAST(0x0000A30F00F77E49 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (280, CAST(0x0000A30F00F781D3 AS DateTime), N'EditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (281, CAST(0x0000A30F00F78413 AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (282, CAST(0x0000A30F00F78C30 AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (283, CAST(0x0000A30F00F7955C AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (284, CAST(0x0000A30F00F79B91 AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (285, CAST(0x0000A30F00F81558 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (286, CAST(0x0000A30F00F81707 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (287, CAST(0x0000A30F00F88134 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (288, CAST(0x0000A30F00F88138 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (289, CAST(0x0000A310012FE5C0 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (290, CAST(0x0000A310012FED8E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (291, CAST(0x0000A310012FF32B AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (292, CAST(0x0000A310012FF38B AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (293, CAST(0x0000A310012FF3D3 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (294, CAST(0x0000A310012FF721 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (295, CAST(0x0000A310012FFA83 AS DateTime), N'ManageRoles', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageRoles/Manage Roles?MenuId=156', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (296, CAST(0x0000A310012FFBD6 AS DateTime), N'GetMenuItemsByRole', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (297, CAST(0x0000A310013000AD AS DateTime), N'AssignRemoveMenuItems', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (298, CAST(0x0000A3100130062C AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (299, CAST(0x0000A31001300A13 AS DateTime), N'AddEditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (300, CAST(0x0000A3100133A4FD AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (301, CAST(0x0000A3100133A94B AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (302, CAST(0x0000A3100133AF1D AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (303, CAST(0x0000A3100133AF3C AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (304, CAST(0x0000A3100133AF8C AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (305, CAST(0x0000A3100133B25C AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (306, CAST(0x0000A3100133B41E AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (307, CAST(0x0000A3100133B57A AS DateTime), N'AddEditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (308, CAST(0x0000A3100133C7CF AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (309, CAST(0x0000A3100133C987 AS DateTime), N'AddEditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (310, CAST(0x0000A3100133D64C AS DateTime), N'SubmitDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (311, CAST(0x0000A3100134ADF4 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (312, CAST(0x0000A3100134B395 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (313, CAST(0x0000A3100134B765 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (314, CAST(0x0000A3100134B782 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (315, CAST(0x0000A3100134B7B9 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (316, CAST(0x0000A3100134B9E5 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (317, CAST(0x0000A3100134BB86 AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (318, CAST(0x0000A3100134C8E8 AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (319, CAST(0x0000A3100135012E AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (320, CAST(0x0000A31001350571 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (321, CAST(0x0000A31001350ACC AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (322, CAST(0x0000A31001350AEE AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (323, CAST(0x0000A31001350B26 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (324, CAST(0x0000A31001350D62 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (325, CAST(0x0000A31001350EAC AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (326, CAST(0x0000A31001356EA1 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (327, CAST(0x0000A31001357359 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (328, CAST(0x0000A3100135783A AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (329, CAST(0x0000A31001357858 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (330, CAST(0x0000A31001357894 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (331, CAST(0x0000A31001357A76 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (332, CAST(0x0000A31001357BC1 AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (333, CAST(0x0000A3100135E2D6 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (334, CAST(0x0000A3100135E8CA AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (335, CAST(0x0000A3100135ED4E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (336, CAST(0x0000A3100135ED6E AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (337, CAST(0x0000A3100135EDA6 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (338, CAST(0x0000A3100135EFB0 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (339, CAST(0x0000A3100135F172 AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (340, CAST(0x0000A31001360285 AS DateTime), N'DelDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (341, CAST(0x0000A31001361855 AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (342, CAST(0x0000A31001361A9F AS DateTime), N'DelProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (343, CAST(0x0000A31001366C5D AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (344, CAST(0x0000A31001366E04 AS DateTime), N'AddEditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (345, CAST(0x0000A3100136733B AS DateTime), N'SubmitDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (346, CAST(0x0000A31001367850 AS DateTime), N'DelDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (347, CAST(0x0000A31001368BDF AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (348, CAST(0x0000A31001368DB8 AS DateTime), N'AddEditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (349, CAST(0x0000A310013691DC AS DateTime), N'SubmitDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (350, CAST(0x0000A31001369968 AS DateTime), N'DelDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (351, CAST(0x0000A3100136CF16 AS DateTime), N'DelDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (352, CAST(0x0000A31001377602 AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (353, CAST(0x0000A3100137786C AS DateTime), N'AddEditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (354, CAST(0x0000A31001377D0C AS DateTime), N'SubmitDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (355, CAST(0x0000A310013781AB AS DateTime), N'DelDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (356, CAST(0x0000A310013EA416 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (357, CAST(0x0000A310013EA902 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (358, CAST(0x0000A310013EA906 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (359, CAST(0x0000A310013EA9EB AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (360, CAST(0x0000A310013EAE79 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (361, CAST(0x0000A310013EAE82 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (362, CAST(0x0000A310013EB488 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (363, CAST(0x0000A310013EBE21 AS DateTime), N'SubmitDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (364, CAST(0x0000A310013ED150 AS DateTime), N'EditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (365, CAST(0x0000A310013ED610 AS DateTime), N'SubmitDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (366, CAST(0x0000A310013EDDE1 AS DateTime), N'AddEditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (367, CAST(0x0000A310013EE0EE AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (368, CAST(0x0000A310013EE864 AS DateTime), N'SubmitProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (369, CAST(0x0000A310013EED53 AS DateTime), N'EditProductGroup', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (370, CAST(0x0000A31100CBB2DC AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (371, CAST(0x0000A31100CBD833 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (372, CAST(0x0000A31100CBDADE AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (373, CAST(0x0000A31100CBE0A6 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (374, CAST(0x0000A31100CBE0C3 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (375, CAST(0x0000A31100CBE0FF AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (376, CAST(0x0000A31100CBE3BF AS DateTime), N'ManageRoles', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageRoles/Manage Roles?MenuId=156', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (377, CAST(0x0000A31100CBE4CF AS DateTime), N'GetMenuItemsByRole', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (378, CAST(0x0000A31100CBE8EF AS DateTime), N'AssignRemoveMenuItems', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (379, CAST(0x0000A31100CBEAE6 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (380, CAST(0x0000A31100CBED2C AS DateTime), N'ProductCategoryMaster', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductCategory/ProductCategoryMaster/Product Category?MenuId=161', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (381, CAST(0x0000A31100CBF028 AS DateTime), N'AddEditProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (382, CAST(0x0000A31100CBF448 AS DateTime), N'SubmitProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (383, CAST(0x0000A31100CBF968 AS DateTime), N'EditProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (384, CAST(0x0000A31100CBFC3B AS DateTime), N'SubmitProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (385, CAST(0x0000A31100CC006B AS DateTime), N'EditProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (386, CAST(0x0000A31100CC0BFC AS DateTime), N'DelProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (387, CAST(0x0000A31100CC0F03 AS DateTime), N'DelProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (388, CAST(0x0000A31100CFF59C AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (389, CAST(0x0000A31100CFFA5E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (390, CAST(0x0000A31100D00465 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (391, CAST(0x0000A31100D00488 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (392, CAST(0x0000A31100D004D6 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (393, CAST(0x0000A31100D0093A AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (394, CAST(0x0000A31100D00C80 AS DateTime), N'ManageRoles', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageRoles/Manage Roles?MenuId=156', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (395, CAST(0x0000A31100D00DF3 AS DateTime), N'GetMenuItemsByRole', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (396, CAST(0x0000A31100D02C23 AS DateTime), N'ManageRoles', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageRoles/Manage Roles?MenuId=156', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (397, CAST(0x0000A31100D0304C AS DateTime), N'AssignRemoveMenuItems', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (398, CAST(0x0000A31100D034CA AS DateTime), N'ProductMaster', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Product/ProductMaster/Product?MenuId=162', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (399, CAST(0x0000A31100D040A2 AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (400, CAST(0x0000A31100D04407 AS DateTime), N'SubmitProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (401, CAST(0x0000A31100D071B0 AS DateTime), N'EditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (402, CAST(0x0000A31100D07484 AS DateTime), N'SubmitProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (403, CAST(0x0000A31100D07A67 AS DateTime), N'DelProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (404, CAST(0x0000A31100D08C6F AS DateTime), N'ProductCategoryMaster', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductCategory/ProductCategoryMaster/Product Category?MenuId=161', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (405, CAST(0x0000A31100D08E9E AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (406, CAST(0x0000A31100D09750 AS DateTime), N'DelDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (407, CAST(0x0000A31100DB7950 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (408, CAST(0x0000A31100DB81BA AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (409, CAST(0x0000A31100DB88D1 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (410, CAST(0x0000A31100DB8905 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (411, CAST(0x0000A31100DB8969 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (412, CAST(0x0000A31100DB8E5B AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (413, CAST(0x0000A31100DB9016 AS DateTime), N'ProductMaster', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Product/ProductMaster/Product?MenuId=162', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (414, CAST(0x0000A31100DB925F AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (415, CAST(0x0000A31100DDE1E6 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (416, CAST(0x0000A31100DDE722 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (417, CAST(0x0000A31100DDEBD1 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (418, CAST(0x0000A31100DDEBF2 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (419, CAST(0x0000A31100DDEC30 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (420, CAST(0x0000A31100DDEE11 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (421, CAST(0x0000A31100DDEFDD AS DateTime), N'ProductMaster', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Product/ProductMaster/Product?MenuId=162', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (422, CAST(0x0000A31100DDF135 AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (423, CAST(0x0000A31100DE0559 AS DateTime), N'ProductMaster', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Product/ProductMaster/Product?MenuId=162', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (424, CAST(0x0000A31100DE06CC AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (425, CAST(0x0000A31100DE9B43 AS DateTime), N'ProductMaster', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Product/ProductMaster/Product?MenuId=162', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (426, CAST(0x0000A31100DE9E1B AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (427, CAST(0x0000A31100E2EBC3 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (428, CAST(0x0000A31100E2F187 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (429, CAST(0x0000A31100E2F5E2 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (430, CAST(0x0000A31100E2F601 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (431, CAST(0x0000A31100E2F63F AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (432, CAST(0x0000A31100E2F807 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (433, CAST(0x0000A31100E2F95F AS DateTime), N'ProductMaster', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Product/ProductMaster/Product?MenuId=162', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (434, CAST(0x0000A31100E2FAF2 AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (435, CAST(0x0000A31100E311AA AS DateTime), N'ProductCategoryMaster', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductCategory/ProductCategoryMaster/Product Category?MenuId=161', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (436, CAST(0x0000A31100E311A2 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (437, CAST(0x0000A31100E31A7F AS DateTime), N'AddEditProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (438, CAST(0x0000A31100E31E27 AS DateTime), N'SubmitProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (439, CAST(0x0000A31100E32330 AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (440, CAST(0x0000A31100E332F5 AS DateTime), N'SubmitProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (441, CAST(0x0000A31100E3390C AS DateTime), N'EditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (442, CAST(0x0000A31100E363B9 AS DateTime), N'EditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (443, CAST(0x0000A31100E3776F AS DateTime), N'SubmitProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (444, CAST(0x0000A31100E3A545 AS DateTime), N'EditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (445, CAST(0x0000A31100E3C51A AS DateTime), N'DelProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (446, CAST(0x0000A31100E3CBBD AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (447, CAST(0x0000A31100E3D22C AS DateTime), N'DelProductCategory', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (448, CAST(0x0000A31100E3E208 AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (449, CAST(0x0000A31100E4131A AS DateTime), N'AddEditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (450, CAST(0x0000A31100E42261 AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (451, CAST(0x0000A31100E43D21 AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (452, CAST(0x0000A31100E43E97 AS DateTime), N'AddEditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (453, CAST(0x0000A31100EE663D AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (454, CAST(0x0000A31100EE6640 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (455, CAST(0x0000A31100EE67F8 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (456, CAST(0x0000A31100EE6C21 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (457, CAST(0x0000A31100EE7F6D AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (458, CAST(0x0000A31100EE7F79 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (459, CAST(0x0000A31100EE85A0 AS DateTime), N'AddEditProduct', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (460, CAST(0x0000A311010143DA AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (461, CAST(0x0000A311010149B5 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (462, CAST(0x0000A31101014E1E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (463, CAST(0x0000A31101014E3D AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (464, CAST(0x0000A31101014E7C AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (465, CAST(0x0000A3110101516B AS DateTime), N'ManageRoles', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageRoles/Manage Roles?MenuId=156', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (466, CAST(0x0000A3110101526B AS DateTime), N'GetMenuItemsByRole', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (467, CAST(0x0000A311010155AA AS DateTime), N'AssignRemoveMenuItems', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (468, CAST(0x0000A31101015730 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (469, CAST(0x0000A31101015901 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (470, CAST(0x0000A31101018D22 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (471, CAST(0x0000A3110101A6EB AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (472, CAST(0x0000A3110101C705 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (473, CAST(0x0000A3110101CDF4 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (474, CAST(0x0000A3110101D2A5 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (475, CAST(0x0000A3110101D2C6 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (476, CAST(0x0000A3110101D305 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (477, CAST(0x0000A3110101D575 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (478, CAST(0x0000A3110101D6D0 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (479, CAST(0x0000A3110101F09A AS DateTime), N'AddEditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (480, CAST(0x0000A3110104E04D AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (481, CAST(0x0000A3110104F148 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (482, CAST(0x0000A3110104F5D0 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (483, CAST(0x0000A3110104F5EF AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (484, CAST(0x0000A3110104F62C AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (485, CAST(0x0000A3110104F89A AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (486, CAST(0x0000A3110104FB49 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (487, CAST(0x0000A3110104FD11 AS DateTime), N'AddEditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (488, CAST(0x0000A311010AB036 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (489, CAST(0x0000A311010AB868 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (490, CAST(0x0000A311010ABCEC AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (491, CAST(0x0000A311010ABD0E AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (492, CAST(0x0000A311010ABD44 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (493, CAST(0x0000A311010AC01E AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (494, CAST(0x0000A311010AC18D AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (495, CAST(0x0000A311010AC33D AS DateTime), N'AddEditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (496, CAST(0x0000A311010AD0C2 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (497, CAST(0x0000A311010AD24D AS DateTime), N'AddEditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (498, CAST(0x0000A311010AE1DB AS DateTime), N'SubmitUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (499, CAST(0x0000A311010B040D AS DateTime), N'EditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (500, CAST(0x0000A311010B185B AS DateTime), N'EditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (501, CAST(0x0000A311010B6858 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (502, CAST(0x0000A311010B6D25 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (503, CAST(0x0000A311010B71C0 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (504, CAST(0x0000A311010B71F6 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (505, CAST(0x0000A311010B7235 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (506, CAST(0x0000A311010B746E AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (507, CAST(0x0000A311010B76C5 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (508, CAST(0x0000A311010B7885 AS DateTime), N'EditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (509, CAST(0x0000A311010B919E AS DateTime), N'EditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (510, CAST(0x0000A311010BE576 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (511, CAST(0x0000A311010BF0B1 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (512, CAST(0x0000A311010BF521 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (513, CAST(0x0000A311010BF551 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (514, CAST(0x0000A311010BF591 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (515, CAST(0x0000A311010BF773 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (516, CAST(0x0000A311010BF8E7 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (517, CAST(0x0000A311010BFCA4 AS DateTime), N'EditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (518, CAST(0x0000A311010C18C0 AS DateTime), N'SubmitUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (519, CAST(0x0000A311010C2986 AS DateTime), N'EditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (520, CAST(0x0000A311010C321D AS DateTime), N'DelUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (521, CAST(0x0000A311010C4323 AS DateTime), N'DelUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (522, CAST(0x0000A311010D1047 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (523, CAST(0x0000A311010D104B AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (524, CAST(0x0000A311010D1141 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (525, CAST(0x0000A311010D15B4 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (526, CAST(0x0000A311010D15BD AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (527, CAST(0x0000A311010D19CC AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (528, CAST(0x0000A311010D47DC AS DateTime), N'DelUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (529, CAST(0x0000A311010D557D AS DateTime), N'DelUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (530, CAST(0x0000A311010D5ACF AS DateTime), N'AddEditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (531, CAST(0x0000A311010DAAC2 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (532, CAST(0x0000A311010DAACA AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (533, CAST(0x0000A311010DABC1 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (534, CAST(0x0000A311010DAFDD AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (535, CAST(0x0000A311010DAFE3 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (536, CAST(0x0000A311010DB37A AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (537, CAST(0x0000A311010DE334 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (538, CAST(0x0000A311010E1616 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (539, CAST(0x0000A311010E23C8 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (540, CAST(0x0000A311010F567F AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (541, CAST(0x0000A311011025D0 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (542, CAST(0x0000A31101103624 AS DateTime), N'DelUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (543, CAST(0x0000A31101103C2D AS DateTime), N'DelUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (544, CAST(0x0000A31101104A8C AS DateTime), N'DelUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (545, CAST(0x0000A31500CC89DE AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (546, CAST(0x0000A31500CC9227 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (547, CAST(0x0000A31500CC9733 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (548, CAST(0x0000A31500CC975B AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (549, CAST(0x0000A31500CC9798 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (550, CAST(0x0000A31500CC9A12 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (551, CAST(0x0000A31500CC9C49 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (552, CAST(0x0000A31500CCA4C5 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=157', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (553, CAST(0x0000A31500CCAB4D AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (554, CAST(0x0000A31500CCAC97 AS DateTime), N'ProductCategoryMaster', N'THSMVC.Controllers.ProductCategoryController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductCategory/ProductCategoryMaster/Product Category?MenuId=161', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (555, CAST(0x0000A31500CCADDE AS DateTime), N'ProductMaster', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Product/ProductMaster/Product?MenuId=162', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (556, CAST(0x0000A31500CCB01A AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (557, CAST(0x0000A31500CCB896 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (558, CAST(0x0000A31500CCB898 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (559, CAST(0x0000A31500CD7AFF AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (560, CAST(0x0000A31500CD7E1C AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (561, CAST(0x0000A31500CD82D6 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (562, CAST(0x0000A31500CD82E0 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (563, CAST(0x0000A31500CD8575 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (564, CAST(0x0000A31500CE4C49 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (565, CAST(0x0000A31500CE4E70 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (566, CAST(0x0000A31500CE4E77 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (567, CAST(0x0000A31500CE4F37 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (568, CAST(0x0000A31500CE5360 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (569, CAST(0x0000A31500CE5369 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (570, CAST(0x0000A31500CE5632 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (571, CAST(0x0000A31500D0395C AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (572, CAST(0x0000A31500D03E4F AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (573, CAST(0x0000A31500D04324 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (574, CAST(0x0000A31500D04345 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (575, CAST(0x0000A31500D04385 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (576, CAST(0x0000A31500D0462B AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (577, CAST(0x0000A31500D04D8C AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=157', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (578, CAST(0x0000A31500D04F26 AS DateTime), N'CreateLot', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (579, CAST(0x0000A31500D188EC AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (580, CAST(0x0000A31500D190AC AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (581, CAST(0x0000A31500D195E2 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (582, CAST(0x0000A31500D19606 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (583, CAST(0x0000A31500D1963F AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (584, CAST(0x0000A31500D19847 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (585, CAST(0x0000A31500D1C660 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (586, CAST(0x0000A31500D1C664 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (587, CAST(0x0000A31500D1DA5B AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (588, CAST(0x0000A31500D1E203 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (589, CAST(0x0000A31500D1E20A AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (590, CAST(0x0000A31500D1E6A2 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (591, CAST(0x0000A31500D257B4 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (592, CAST(0x0000A31500D259EA AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (593, CAST(0x0000A31500D259EC AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (594, CAST(0x0000A31500D25A9E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (595, CAST(0x0000A31500D26052 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (596, CAST(0x0000A31500D2605C AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (597, CAST(0x0000A31500D26283 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (598, CAST(0x0000A31500D32CFE AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (599, CAST(0x0000A31500D330CA AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (600, CAST(0x0000A31500D330CD AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (601, CAST(0x0000A31500D5116E AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (602, CAST(0x0000A31500D51817 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (603, CAST(0x0000A31500D51C82 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (604, CAST(0x0000A31500D51CA0 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (605, CAST(0x0000A31500D51CD5 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (606, CAST(0x0000A31500D51ED6 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (607, CAST(0x0000A31500D52CB6 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (608, CAST(0x0000A31500D58E70 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (609, CAST(0x0000A31500D592FE AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (610, CAST(0x0000A31500D5988E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (611, CAST(0x0000A31500D598AE AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (612, CAST(0x0000A31500D598E3 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (613, CAST(0x0000A31500D59AD5 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (614, CAST(0x0000A31500D5A729 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (615, CAST(0x0000A31500D64BFA AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (616, CAST(0x0000A31500D66FF0 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (617, CAST(0x0000A31500D6787D AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (618, CAST(0x0000A31500D67A9F AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (619, CAST(0x0000A31500D717D8 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (620, CAST(0x0000A31500D7733C AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (621, CAST(0x0000A31500D78CB3 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (622, CAST(0x0000A31500D82BFC AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (623, CAST(0x0000A31500D82BFD AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (624, CAST(0x0000A31500D82CF8 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (625, CAST(0x0000A31500D8328F AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (626, CAST(0x0000A31500D8329E AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (627, CAST(0x0000A31500D8412B AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (628, CAST(0x0000A31500D8462D AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (629, CAST(0x0000A31500D8661C AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (630, CAST(0x0000A31500D8E6F9 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (631, CAST(0x0000A31500D8FC11 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (632, CAST(0x0000A31500D94B3F AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (633, CAST(0x0000A31500DC687D AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (634, CAST(0x0000A31500DC6F16 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (635, CAST(0x0000A31500DC73A8 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (636, CAST(0x0000A31500DC73CD AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (637, CAST(0x0000A31500DC740C AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (638, CAST(0x0000A31500DC76CA AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (639, CAST(0x0000A31500DC8B62 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (640, CAST(0x0000A31500DCF1CA AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (641, CAST(0x0000A31500DD9E19 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (642, CAST(0x0000A31500DDA2B1 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (643, CAST(0x0000A31500DDA8AD AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (644, CAST(0x0000A31500DDA8CC AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (645, CAST(0x0000A31500DDA902 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (646, CAST(0x0000A31500DDAAED AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (647, CAST(0x0000A31500DDB558 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (648, CAST(0x0000A31500DDED99 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (649, CAST(0x0000A31500DE4836 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (650, CAST(0x0000A31500DEAE28 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (651, CAST(0x0000A31500DF0219 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (652, CAST(0x0000A31500DF1701 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (653, CAST(0x0000A31500DF2192 AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (654, CAST(0x0000A31500DF25CF AS DateTime), N'DelLotAssignment', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (655, CAST(0x0000A31500E0DEDC AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (656, CAST(0x0000A31500E0DEE0 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (657, CAST(0x0000A31500E0DFA4 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (658, CAST(0x0000A31500E0E3E7 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (659, CAST(0x0000A31500E0E3F2 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (660, CAST(0x0000A31500E0E602 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (661, CAST(0x0000A31500E0E7C1 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (662, CAST(0x0000A31500E0E951 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (663, CAST(0x0000A31500E175A0 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (664, CAST(0x0000A31500E1824C AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (665, CAST(0x0000A31500E18CD5 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (666, CAST(0x0000A31500E2C04B AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (667, CAST(0x0000A31500E32784 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (668, CAST(0x0000A31500E38019 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (669, CAST(0x0000A31500E39688 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (670, CAST(0x0000A31500E3ACC8 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (671, CAST(0x0000A31500E3D442 AS DateTime), N'TimeoutExpired', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (672, CAST(0x0000A31500E3D471 AS DateTime), N'SessionExpire', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (673, CAST(0x0000A31500E3D67A AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (674, CAST(0x0000A31500E3DB3B AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (675, CAST(0x0000A31500E3DB64 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (676, CAST(0x0000A31500E3DBBD AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (677, CAST(0x0000A31500E3DD59 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (678, CAST(0x0000A31500E3DE7B AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (679, CAST(0x0000A31500E3DF99 AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (680, CAST(0x0000A31500E3E98B AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (681, CAST(0x0000A31500E3F2F7 AS DateTime), N'DelUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (682, CAST(0x0000A31500E3F888 AS DateTime), N'DelUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (683, CAST(0x0000A31500E3FE5B AS DateTime), N'AddEditUser', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (684, CAST(0x0000A31500E401F8 AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (685, CAST(0x0000A31500E401FC AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (686, CAST(0x0000A31500FA3D3E AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (687, CAST(0x0000A31500FA4A9E AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (688, CAST(0x0000A31500FA52A3 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (689, CAST(0x0000A31500FA52C3 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (690, CAST(0x0000A31500FA5301 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (691, CAST(0x0000A31500FA54F0 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (692, CAST(0x0000A31500FA5701 AS DateTime), N'ProductMaster', N'THSMVC.Controllers.ProductController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Product/ProductMaster/Product?MenuId=162', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (693, CAST(0x0000A31500FA59B9 AS DateTime), N'DealerMaster', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Dealer/DealerMaster/Dealer?MenuId=160', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (694, CAST(0x0000A31500FA5B14 AS DateTime), N'AddEditDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (695, CAST(0x0000A31500FA6295 AS DateTime), N'SubmitDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (696, CAST(0x0000A31500FA813B AS DateTime), N'DelDealer', N'THSMVC.Controllers.DealerController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (697, CAST(0x0000A31500FA86CC AS DateTime), N'UserMaster', N'THSMVC.Controllers.UserController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/User/UserMaster/User?MenuId=163', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (698, CAST(0x0000A31500FA8907 AS DateTime), N'LotMaster', N'THSMVC.Controllers.LotController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Lot/LotMaster/Lot?MenuId=155', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (699, CAST(0x0000A315010E93A1 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (700, CAST(0x0000A315010E9B0B AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (701, CAST(0x0000A315010E9FDC AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (702, CAST(0x0000A315010E9FFE AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (703, CAST(0x0000A315010EA036 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (704, CAST(0x0000A315010EA287 AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (705, CAST(0x0000A315010EA6AC AS DateTime), N'ManageRoles', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/ManageRoles/Manage Roles?MenuId=156', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (706, CAST(0x0000A315010EA83A AS DateTime), N'GetMenuItemsByRole', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (707, CAST(0x0000A315010EAC81 AS DateTime), N'AssignRemoveMenuItems', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (708, CAST(0x0000A315010EB03C AS DateTime), N'RoleMaster', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Role/RoleMaster/Roles?MenuId=165', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (709, CAST(0x0000A315010EDF94 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (710, CAST(0x0000A315010EE4F0 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (711, CAST(0x0000A315010EEAF3 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (712, CAST(0x0000A315010EEB16 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (713, CAST(0x0000A315010EEB61 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (714, CAST(0x0000A315010EED2A AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (715, CAST(0x0000A315010EEE9B AS DateTime), N'RoleMaster', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Role/RoleMaster/Roles?MenuId=165', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (716, CAST(0x0000A315010F2766 AS DateTime), N'RoleMaster', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Role/RoleMaster/Roles?MenuId=165', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (717, CAST(0x0000A315010F2CF7 AS DateTime), N'EditRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (718, CAST(0x0000A315010F3A34 AS DateTime), N'SubmitRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (719, CAST(0x0000A315010F40D4 AS DateTime), N'DelRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (720, CAST(0x0000A315010FA59A AS DateTime), N'EditRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (721, CAST(0x0000A315010FA881 AS DateTime), N'SubmitRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (722, CAST(0x0000A315010FAE40 AS DateTime), N'SubmitRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (723, CAST(0x0000A31501106C03 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (724, CAST(0x0000A315011079D7 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (725, CAST(0x0000A31501108102 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (726, CAST(0x0000A31501108123 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (727, CAST(0x0000A31501108171 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (728, CAST(0x0000A3150110835F AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (729, CAST(0x0000A315011084A8 AS DateTime), N'RoleMaster', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Role/RoleMaster/Roles?MenuId=165', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (730, CAST(0x0000A31501108830 AS DateTime), N'DelRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (731, CAST(0x0000A3150110C35F AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (732, CAST(0x0000A3150110C86F AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (733, CAST(0x0000A3150110CDF7 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (734, CAST(0x0000A3150110CE1B AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (735, CAST(0x0000A3150110CE51 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (736, CAST(0x0000A3150110D00E AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (737, CAST(0x0000A3150110D18D AS DateTime), N'RoleMaster', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Role/RoleMaster/Roles?MenuId=165', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (738, CAST(0x0000A3150110D35C AS DateTime), N'EditRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (739, CAST(0x0000A3150110D7C8 AS DateTime), N'DelRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (740, CAST(0x0000A3150110F087 AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (741, CAST(0x0000A3150110F30B AS DateTime), N'LogOff', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (742, CAST(0x0000A3150110F30D AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (743, CAST(0x0000A3150110F3AC AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (744, CAST(0x0000A3150110F80C AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (745, CAST(0x0000A3150110F816 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (746, CAST(0x0000A3150110FE19 AS DateTime), N'DelRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (747, CAST(0x0000A3150111821B AS DateTime), N'Index', N'THSMVC.Controllers.HomeController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (748, CAST(0x0000A31501118E00 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (749, CAST(0x0000A31501119315 AS DateTime), N'LogOn', N'THSMVC.Controllers.AccountController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (750, CAST(0x0000A31501119334 AS DateTime), N'Empty', N'THSMVC.Controllers.SharedController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/12?Id=Home', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (751, CAST(0x0000A31501119377 AS DateTime), N'Welcome', N'THSMVC.Controllers.AdminController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Admin/Welcome/Home?MenuId=12', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (752, CAST(0x0000A3150111953B AS DateTime), N'ProductGroupMaster', N'THSMVC.Controllers.ProductGroupController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/ProductGroup/ProductGroupMaster/Masters?MenuId=158', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (753, CAST(0x0000A31501119692 AS DateTime), N'RoleMaster', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'http://localhost:1101/Role/RoleMaster/Roles?MenuId=165', N'::1', N'4')
GO
INSERT [dbo].[SiteLog] ([ID], [TimeStamp], [Action], [Controller], [IPAddress], [URL], [HostAddress], [UserID]) VALUES (754, CAST(0x0000A31501119A7B AS DateTime), N'DelRole', N'THSMVC.Controllers.RoleController', N'fe80::555a:6ddd:ff7a:543f%11', N'', N'::1', N'4')
GO
SET IDENTITY_INSERT [dbo].[SiteLog] OFF
GO
SET IDENTITY_INSERT [dbo].[User] ON 

GO
INSERT [dbo].[User] ([Id], [UserName], [Password], [RoleId], [Email], [InstanceId], [IsApproved], [IsLockedOut], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockedOutDate], [FailedPasswordAttemptCount], [ChangePwdonLogin], [Comment]) VALUES (3, N'admin', N'WmZC2hY0yEA604185n48Lg==', NULL, N'kollisreekanth@gmail.com', NULL, 1, 0, 0, CAST(0x00009FEC00F61873 AS DateTime), NULL, NULL, CAST(0x0000A3150111932D AS DateTime), NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[User] ([Id], [UserName], [Password], [RoleId], [Email], [InstanceId], [IsApproved], [IsLockedOut], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockedOutDate], [FailedPasswordAttemptCount], [ChangePwdonLogin], [Comment]) VALUES (4, N'Admin', N'+ZQqEZYY07w=', 1, N'admin@pjewels.com', 1, 1, 0, 3, CAST(0x00009FF20108BE2C AS DateTime), NULL, NULL, CAST(0x0000A19100F3F7DE AS DateTime), NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[User] ([Id], [UserName], [Password], [RoleId], [Email], [InstanceId], [IsApproved], [IsLockedOut], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockedOutDate], [FailedPasswordAttemptCount], [ChangePwdonLogin], [Comment]) VALUES (5, N'u1', N'rT3bOaoJcBw=', 1, N'e', 1, 1, 0, 4, CAST(0x0000A311010AE814 AS DateTime), 4, CAST(0x0000A311010C1DDE AS DateTime), NULL, NULL, CAST(0x0000A31500E3F2FD AS DateTime), NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[User] OFF
GO
SET IDENTITY_INSERT [dbo].[UserDetails] ON 

GO
INSERT [dbo].[UserDetails] ([Id], [UserId], [Name], [Address], [City], [State], [PinCode], [Mobile], [Phone]) VALUES (1, 5, N'u1', N'a', N'c', N's', N'p', N'm', N'p')
GO
SET IDENTITY_INSERT [dbo].[UserDetails] OFF
GO
SET IDENTITY_INSERT [dbo].[UserMenu] ON 

GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (78, 1, 4, 1, 12, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC93 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (79, 1, 5, 1, 12, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC93 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (80, 1, 4, 1, 154, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC93 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (81, 1, 5, 1, 154, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC93 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (82, 1, 4, 1, 156, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (83, 1, 5, 1, 156, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (84, 1, 4, 1, 157, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (85, 1, 5, 1, 157, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (86, 1, 4, 1, 155, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (87, 1, 5, 1, 155, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (88, 1, 4, 1, 159, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (89, 1, 5, 1, 159, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (90, 1, 4, 1, 158, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (91, 1, 5, 1, 158, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC94 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (92, 1, 4, 1, 160, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC95 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (93, 1, 5, 1, 160, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC95 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (94, 1, 4, 1, 161, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC95 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (95, 1, 5, 1, 161, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC95 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (96, 1, 4, 1, 162, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC95 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (97, 1, 5, 1, 162, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC95 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (98, 1, 4, 1, 163, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC96 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (99, 1, 5, 1, 163, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC96 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (100, 1, 4, 1, 164, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC96 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (101, 1, 5, 1, 164, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC96 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (102, 1, 4, 1, 165, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC96 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (103, 1, 5, 1, 165, CAST(0x0000A2F100000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 4, CAST(0x0000A315010EAC96 AS DateTime), NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[UserMenu] OFF
GO
ALTER TABLE [dbo].[Stone] ADD  CONSTRAINT [DF_Stone_IsStoneWeightless]  DEFAULT ((0)) FOR [IsStoneWeightless]
GO
ALTER TABLE [dbo].[LotUserMapping]  WITH CHECK ADD  CONSTRAINT [FK_LotUserMapping_Lot] FOREIGN KEY([LotId])
REFERENCES [dbo].[Lot] ([LotId])
GO
ALTER TABLE [dbo].[LotUserMapping] CHECK CONSTRAINT [FK_LotUserMapping_Lot]
GO
ALTER TABLE [dbo].[LotUserMapping]  WITH CHECK ADD  CONSTRAINT [FK_LotUserMapping_LotStatus] FOREIGN KEY([StatusId])
REFERENCES [dbo].[LotStatus] ([StatusId])
GO
ALTER TABLE [dbo].[LotUserMapping] CHECK CONSTRAINT [FK_LotUserMapping_LotStatus]
GO
ALTER TABLE [dbo].[LotUserMapping]  WITH CHECK ADD  CONSTRAINT [FK_LotUserMapping_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[User] ([Id])
GO
ALTER TABLE [dbo].[LotUserMapping] CHECK CONSTRAINT [FK_LotUserMapping_User]
GO
USE [master]
GO
ALTER DATABASE [PJ] SET  READ_WRITE 
GO
