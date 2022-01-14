/*
 First example (message receive)
 */

-- Create users
insert into users(FirstName, LastName) values ('Ivan', 'Petrov');
insert into users(FirstName, LastName) values ('Ivan', 'Ivanov');


-- Check users ratings
select *
from users;

-- Check logs
select *
from logs;

-- Send message
insert into messages(UserId, Text) values (1, 'Ты очень плохой маг');

-- Check messages
select *
from messages;

-- Check users ratings
select *
from users;

--Check logs
select *
from logs;


/*
 Second example (adding friends)
 */

-- Set input values
update users set rating = 0 where UserId = 1; -- Petrov
update users set rating = -10 where UserId = 2; -- Ivanov

-- Check users ratings
select *
from users;

insert into friends(Friend1, Friend2) values (1, 2);

-- Check users ratings
select *
from users;

--Check logs
select *
from logs;


/*
 Third example (group adding)
 */

-- Create new group
insert into groups(Name, Rating) values ('Maglbl', -10);
-- Set input values
update users set rating = -5 where UserId = 2; -- Ivanov

-- Check users ratings
select *
from users;

-- Check group
select *
from groups;

-- Adding user to group
insert into UserGroups(UserId, GroupId) values (2, 1);

-- Check users ratings
select *
from users;

-- Check group
select *
from groups;

--Check logs
select *
from logs;


/*
 Additional examples
 */

/*
 Example (Check Results table)
 */
insert into users(FirstName, LastName, Rating) values ('Good', 'Student', 99);
insert into users(FirstName, LastName, Rating) values ('Bad', 'Student', -99);

-- Check users ratings
select *
from users;

-- Check Results table
select *
from results;

-- Adding new messages
insert into messages(UserId, Text) values (3, 'хорошо');
insert into messages(UserId, Text) values (4, 'плохо');

-- Check users ratings
select *
from users;

-- Check Results table
select *
from results;


-- Adding new messages
insert into messages(UserId, Text) values (3, 'хорошо');
insert into messages(UserId, Text) values (4, 'плохо');


-- Check users ratings
select *
from users;

-- Check Results table (No new messages)
select *
from results;

-- Reduce Good Student Rating
insert into messages(UserId, Text) values (3, 'плохо');
insert into messages(UserId, Text) values (3, 'плохо');
insert into messages(UserId, Text) values (3, 'плохо');
insert into messages(UserId, Text) values (3, 'плохо');

-- Check users ratings
select *
from users;

-- Check Results table (No new messages)
select *
from results;

-- Restore good student rating
insert into messages(UserId, Text) values (3, 'хорошо');
insert into messages(UserId, Text) values (3, 'хорошо');
insert into messages(UserId, Text) values (3, 'хорошо');
insert into messages(UserId, Text) values (3, 'хорошо');
insert into messages(UserId, Text) values (3, 'хорошо');


-- Check users ratings
select *
from users;

-- Check Results table (+1 row)
select *
from results;

--Check logs
select *
from logs;