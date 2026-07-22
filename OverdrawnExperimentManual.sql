use OverdrawnExperiment;

set nocount on;

if OBJECT_ID('[dbo].[Balance]') is null
	create table [dbo].[Balance] (
		UserID int not null identity primary key clustered,
		Amount decimal(19,2) not null,
	);

truncate table [dbo].[Balance];
go

insert into [dbo].[Balance] (Amount) 
values (100000000);
go 5 -- <== Do the insert many times.

declare @UserID int = (
	select CHECKSUM(newid()) % MAX(UserID) + 1
	from [dbo].[Balance]
);

begin tran;

declare @Withdrawal decimal(19,2) = (
	select Amount * 0.6
	from [dbo].[Balance] with (holdlock, xlock)
	where UserID = @UserID
);

update [dbo].[Balance]
set Amount -= @Withdrawal
where UserID = @UserID;

commit;

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


