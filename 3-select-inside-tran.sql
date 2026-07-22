use OverdrawnExperiment;

set nocount on;

if OBJECT_ID('[dbo].[Balance]') is null
	create table [dbo].[Balance] (
		UserID int not null identity primary key clustered,
		Amount decimal(19,2) not null,
	);

truncate table [dbo].[Balance];
go

insert into [dbo].[Balance] (Amount) values (100000000);
go 5 -- <== Do the insert many times.

/*
	ALTER DATABASE OverdrawnExperiment SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	ALTER DATABASE OverdrawnExperiment SET READ_COMMITTED_SNAPSHOT OFF;
	ALTER DATABASE OverdrawnExperiment SET MULTI_USER;
--*/
set transaction isolation level read committed; -- without SNAPSHOT
go

declare @UserID int = (
	select CHECKSUM(newid()) % MAX(UserID) + 1
	from [dbo].[Balance]
);

BEGIN TRAN;

DECLARE @Withdrawal decimal(19,2) = (
	SELECT Amount * 0.6
	FROM [dbo].[Balance]
	WHERE UserID = @UserID
);

UPDATE [dbo].[Balance]
SET Amount -= @Withdrawal
WHERE UserID = @UserID;

COMMIT;

if (
	select Amount
	from [dbo].[Balance]
	where UserID = @UserID
) < 0 begin;
	update [dbo].[Balance]
	set Amount = 0
	where UserID = @UserID;

	print 'Account overdrawn.';
end;
go 10000


