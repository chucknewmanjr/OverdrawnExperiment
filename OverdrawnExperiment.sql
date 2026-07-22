use OverdrawnExperiment;
go

drop table if exists [dbo].[Balance];
go

create table [dbo].[Balance] (
	UserID int not null identity primary key clustered,
	Amount decimal(19,2) not null,
);
go

set nocount on;
go

insert into [dbo].[Balance] (Amount) 
values (100000000);
go 5 -- <== Do the insert many times.

create or alter proc [dbo].[p_Withdraw] as
	/*
		EXEC [dbo].[p_Withdraw];
	*/
	set nocount, xact_abort on;

	declare @ThisLoop int = 0;

	while @ThisLoop < 1000 begin;
		set @ThisLoop += 1;

		declare @UserID int = (
			select CHECKSUM(newid()) % MAX(UserID) + 1
			from [dbo].[Balance]
		);

		begin try;

			begin tran;

			declare @Withdrawal decimal(19,2) = (
				select Amount * 0.6
				from [dbo].[Balance] with (updlock)
				where UserID = @UserID
			);

			update [dbo].[Balance]
			set Amount -= @Withdrawal
			where UserID = @UserID;

			if (
				select Amount
				from [dbo].[Balance]
				where UserID = @UserID
			) < 0
				throw 50000, 'Account overdrawn.', 1;

			commit;
		end try
		begin catch;
			if XACT_STATE() <> 0 rollback;

			throw; -- Rethrow the error.
		end catch;
	end;
go

EXEC [Async].[p_Execute] 10, 'EXEC [dbo].[p_Withdraw];', 0; 

select * from [Async].[f_SessionMessage](default) order by 1;

select Amount
	, count(*) as [RowCount]
from [dbo].[Balance] 
group by Amount 
order by Amount;



