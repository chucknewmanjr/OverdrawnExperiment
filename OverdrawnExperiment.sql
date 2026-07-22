use OverdrawnExperiment;
go

drop table if exists [dbo].[Balance];
go

create table [dbo].[Balance] (
	UserID int not null identity primary key clustered,
	Amount decimal(8,2) not null,
);
go

set nocount on;
go

insert into [dbo].[Balance] (Amount) 
values (100000);
go 100 -- <== Do the insert many times.

create or alter proc [dbo].[p_Withdraw] as
	/*
		EXEC [dbo].[p_Withdraw];
	*/
	set nocount, xact_abort on;

	declare @ThisLoop int = 0;

	while @ThisLoop < 100 begin;
		set @ThisLoop += 1;

		declare @UserID int = (
			select CHECKSUM(newid()) % MAX(UserID) + 1
			from [dbo].[Balance]
		);

		begin try;

			begin tran;

			declare @Amount decimal(8,2) = (
				select Amount * 0.4
				from [dbo].[Balance]
				where UserID = @UserID
			);

			--waitfor delay '00:00:00.100';

			update [dbo].[Balance]
			set Amount = @Amount
			where UserID = @UserID;

			if (
				select Amount
				from [dbo].[Balance]
				where UserID = @UserID
			) < 0 begin;
				rollback;

				throw 50000, 'Account overdrawn.', 1;
			end;

			commit;
		end try
		begin catch;
			rollback;

			throw; -- Rethrow the error.
		end catch;

	end;
go

EXEC [Async].[p_Execute] 100, 'EXEC [dbo].[p_Withdraw];', 0; 

select * from [Async].[f_SessionMessage](default) order by 1;

select Amount
	, count(*) as [RowCount]
	--, MIN(UserID) as MinUserID
	--, MAX(UserID) as MaxUserID
from [dbo].[Balance] 
group by Amount 
order by Amount;



