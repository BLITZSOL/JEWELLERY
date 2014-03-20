
USE [PJ]
GO
/****** Object:  StoredProcedure [dbo].[stp_Assign_Remove_MenuItems_Role]    Script Date: 3/20/2014 11:45:42 AM ******/
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
/****** Object:  StoredProcedure [dbo].[stp_Assign_Remove_MenuItems_User]    Script Date: 3/20/2014 11:45:42 AM ******/
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
/****** Object:  StoredProcedure [dbo].[stp_Get_Menuitems_By_Role_Id]    Script Date: 3/20/2014 11:45:42 AM ******/
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
/****** Object:  StoredProcedure [dbo].[stp_Intial_Menus_For_Admin]    Script Date: 3/20/2014 11:45:42 AM ******/
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
/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 3/20/2014 11:45:42 AM ******/
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
/****** Object:  Table [dbo].[Instance]    Script Date: 3/20/2014 11:45:42 AM ******/
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
 CONSTRAINT [PK_Instance] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Log4Net_Error]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[Menu]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[MenuAccessRight]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[MenuGroup]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[MenuRight]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[Right]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[Role]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[RoleMenu]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[SiteLog]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[User]    Script Date: 3/20/2014 11:45:43 AM ******/
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
/****** Object:  Table [dbo].[UserMenu]    Script Date: 3/20/2014 11:45:43 AM ******/
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
SET IDENTITY_INSERT [dbo].[Instance] ON 

GO
INSERT [dbo].[Instance] ([Id], [Name], [ParentInstance], [Address], [PIN], [Phone], [Mobile], [CreatedDate], [LicenseStartDate], [LicenseEndDate], [Status]) VALUES (1, N'POOJA', NULL, N'AS RAO Nagar', NULL, NULL, NULL, CAST(0x0000A2F100000000 AS DateTime), CAST(0x4C380B00 AS Date), CAST(0xB9390B00 AS Date), NULL)
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
SET IDENTITY_INSERT [dbo].[Log4Net_Error] OFF
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
SET IDENTITY_INSERT [dbo].[Role] ON 

GO
INSERT [dbo].[Role] ([Id], [InstanceId], [Role], [RoleDesc], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (1, 1, N'Administrator', N'Admin', 3, CAST(0x00009FF20108BE1F AS DateTime), NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[Role] OFF
GO
SET IDENTITY_INSERT [dbo].[RoleMenu] ON 

GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (217, 1, 1, 12, 3, CAST(0x0000A2F100000000 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[RoleMenu] ([Id], [InstanceId], [RoleId], [MenuId], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (218, 1, 1, 154, 3, CAST(0x0000A2F100000000 AS DateTime), NULL, NULL, NULL)
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
SET IDENTITY_INSERT [dbo].[SiteLog] OFF
GO
SET IDENTITY_INSERT [dbo].[User] ON 

GO
INSERT [dbo].[User] ([Id], [UserName], [Password], [RoleId], [Email], [InstanceId], [IsApproved], [IsLockedOut], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockedOutDate], [FailedPasswordAttemptCount], [ChangePwdonLogin], [Comment]) VALUES (3, N'admin', N'WmZC2hY0yEA604185n48Lg==', NULL, N'kollisreekanth@gmail.com', NULL, 1, 0, 0, CAST(0x00009FEC00F61873 AS DateTime), NULL, NULL, CAST(0x0000A2F100EEAADB AS DateTime), NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[User] ([Id], [UserName], [Password], [RoleId], [Email], [InstanceId], [IsApproved], [IsLockedOut], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [LastLoginDate], [LastPasswordChangedDate], [LastLockedOutDate], [FailedPasswordAttemptCount], [ChangePwdonLogin], [Comment]) VALUES (4, N'Admin', N'+ZQqEZYY07w=', 1, N'admin@pjewels.com', 1, 1, 0, 3, CAST(0x00009FF20108BE2C AS DateTime), NULL, NULL, CAST(0x0000A19100F3F7DE AS DateTime), NULL, NULL, NULL, 0, NULL)
GO
SET IDENTITY_INSERT [dbo].[User] OFF
GO
SET IDENTITY_INSERT [dbo].[UserMenu] ON 

GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (1, 1, 4, 1, 12, CAST(0x0000A2F000000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 3, CAST(0x0000A2F100000000 AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[UserMenu] ([Id], [InstanceId], [UserId], [RoleId], [MenuId], [FromDate], [ToDate], [Flag], [CreatedBy], [CreatedDate], [EditedBy], [EditedDate], [Status]) VALUES (2, 1, 4, 1, 154, CAST(0x0000A2F000000000 AS DateTime), CAST(0x0000A45E00000000 AS DateTime), 1, 3, CAST(0x0000A2F100000000 AS DateTime), NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[UserMenu] OFF
GO
USE [master]
GO
ALTER DATABASE [PJ] SET  READ_WRITE 
GO
