/* 
    File descriptions:
    - Install.sql - creating tables, functions, procedures, triggers for database
    - Truncate_all_tables.sql - contains code for clear all tables
    - Check.sql - script for checking tables data
    - Examples.sql - script with examples (from task + one additional)
    - Uninstall.sql - removing all created objects
*/


/*

 DDL для основных таблиц базы

 */

-- Create Users table
create table users (
    UserId number generated always as identity (start with 1 increment by 1 nocycle),
    FirstName varchar2(100) not null,
    LastName varchar2(100) not null,
    Rating number default 0 not null
);

alter table users add constraint users_pk_userid primary key (UserId);


-- Create Groups table
create table groups (
    GroupId number generated always as identity (start with 1 increment by 1 nocycle),
    Name varchar2(100) not null,
    Rating number default 0 not null
);

alter table groups add constraint groups_pk_groupid primary key (GroupId);
alter table groups add constraint groups_u_name unique (Name);


-- Create UserGroups table
create table UserGroups (
    UserId number not null,
    GroupId number not null
);

alter table UserGroups add constraint usergroups_fk_userid_users_userid foreign key (UserId) references users(UserId);
alter table UserGroups add constraint usergroups_fk_groupid_groups_groupid foreign key (GroupId) references groups(GroupId);

--Пользователь не может дважды состоять в одной и той же группе
alter table UserGroups add constraint usergroups_u_groupid_userid unique (UserId, GroupId);


-- Create Messages table
create table messages (
    MessageId number generated always as identity (start with 1 increment by 1 nocycle),
    UserId number not null,
    Text varchar2(1000) not null
);

alter table messages add constraint messages_pk_messageid primary key (MessageId);
alter table messages add constraint messages_fk_userid_users_userid foreign key (UserId) references users(UserId);


-- Create table Friends
create table friends (
    Friend1 number not null,
    Friend2 number not null
);

alter table friends add constraint friends_fk_friend1_users_userid foreign key (Friend1) references users(UserId);
alter table friends add constraint friends_fk_friend2_users_userid foreign key (Friend2) references users(UserId);

-- Два пользователя не могут стать друзьями дважды
alter table friends add constraint friends_u_friend1_friend2 unique (Friend1, Friend2);


--Create Results table
create table results (
    EntryId number generated always as identity (start with 1 increment by 1 nocycle),
    UserId number not null,
    Rating number not null,
    DateTime timestamp not null
);

alter table results add constraint results_pk_entryid primary key (EntryId);
alter table results add constraint results_fk_userid_users_id foreign key (UserId) references users(UserId);

-- Create Logs table
-- Сохраняет информация о создании пользоавтелей, о удалении пользователей, о добавление друзей,
-- о получении сообщений, о добавлении пользователей в группы
create table logs (
    LogId number generated always as identity (start with 1 increment by 1 nocycle),
    DateTime timestamp not null,
    UserId number not null,
    OldRating number,
    NewRating number,
    Action varchar2(1000) not null
);

alter table logs add constraint logs_pk_logid primary key (LogId);


/*

 DDL для вспомогательных таблиц базы

 */

-- Create KeyWords table
-- Таблица хранит ключевые слова сообщения по которым начисляются, забираются балы у пользователей
-- По заданию только два ключевых слова, в дальнейшем можно расширять на сколько угодно слов, с любым изменением рейтинга
create table KeyWords (
    Pattern varchar2(100) not null,
    RatingDifference number not null
);

insert into KeyWords(Pattern, RatingDifference) values ('плохо', -1);
insert into KeyWords(Pattern, RatingDifference) values ('хорошо', 1);


/*

 Создание вспомогательных процедур и функций

 */

-- Функция вычисляет рейтинг сообщения. Т.е. колличество баллов которые добавится пользователю, за получение этого сообщения
create or replace function calculate_message_rating(p_message varchar2) return number
as
    query_block constant varchar2(500) := q'[
    select distinct
       sum(
           case
               when instr(lower(:1), Pattern) != 0
                   then RatingDifference
               else 0 end)
    from KeyWords]';
    score number;
begin
    execute immediate query_block
        into score
        using in p_message;

    return score;
end calculate_message_rating;

-- Функция для получения текущего рейтинга пользователя
create or replace function get_user_rating(p_userid users.UserId%type) return number
as
    query_block constant varchar2(500) := q'[select rating from users where UserId = :1]';
    rating number;
begin
    execute immediate query_block into rating using p_userid;
    return rating;
end get_user_rating;

-- Функция для получения текущего рейтинга группы
create or replace function get_group_rating(p_groupid groups.GroupId%type) return number
as
    query_block constant varchar2(500) := q'[select rating from groups where GroupId = :1]';
    rating number;
begin
    execute immediate query_block into rating using p_groupid;
    return rating;
end get_group_rating;


/*

 Создание процедур для логирования действий

 */

-- Добавление лога при создании пользователя
create or replace procedure log_user_added(p_userid users.UserId%type, p_rating users.Rating%type)
as
begin
    insert into logs(DateTime, UserId, OldRating, NewRating, Action) values (systimestamp, p_userid, null, p_rating, 'User ' || p_userid || ' created');
end log_user_added;

-- Добавление лога при удалении пользователя
create or replace procedure log_user_deleted(p_userid users.UserId%type, p_rating users.Rating%type)
as
begin
    insert into logs(DateTime, UserId, OldRating, NewRating, Action) values (systimestamp, p_userid, p_rating, null, 'User ' || p_userid || ' deleted');
end log_user_deleted;

-- Добавление лога когда пользователи становятся друзьями
create or replace procedure log_users_friendship(
        p_user1 users.UserId%type,
        p_user2 users.UserId%type,

        p_user1_rating_before users.Rating%type,
        p_user1_rating_after users.Rating%type,

        p_user2_rating_before users.Rating%type,
        p_user2_rating_after users.Rating%type)
as
begin
    insert into logs(DateTime, UserId, OldRating, NewRating, Action) values (systimestamp, p_user1, p_user1_rating_before, p_user1_rating_after, 'User ' || p_user1 || ' make friend. Friend: ' || p_user2);
    insert into logs(DateTime, UserId, OldRating, NewRating, Action) values (systimestamp, p_user2, p_user2_rating_before, p_user2_rating_after, 'User ' || p_user2 || ' make friend. Friend: ' || p_user1);
end log_users_friendship;

-- Добавление лога при получении нового сообщения
create or replace procedure log_new_message(p_userid users.UserId%type, p_messageid messages.MessageId%type, p_rating_before users.Rating%type, p_rating_after users.Rating%type)
as
begin
    insert into logs(DateTime, UserId, OldRating, NewRating, Action) values (systimestamp, p_userid, p_rating_before, p_rating_after, 'User ' || p_userid || ' receive message with id ' || p_messageid);
end log_new_message;

-- Добавление лога при добавление пользователя в группу
create or replace procedure log_user_added_to_group(p_userid users.UserId%type, p_groupid groups.GroupId%type, p_rating_before users.Rating%type, p_rating_after users.Rating%type)
as
begin
    insert into logs(DateTime, UserId, OldRating, NewRating, Action) values (systimestamp, p_userid, p_rating_before, p_rating_after, 'User ' || p_userid || ' was added to group ' || p_groupid);
end log_user_added_to_group;


/*

 Создание триггеров на таблицы

 */

-- Триггер на добавление нового сообщения, изменяет рейтинг пользователя, логирует получение сообщения
create or replace trigger message_ai_trg
    after insert on messages for each row
declare
    rating_before number;
    rating_after number;
    score number;
begin
    rating_before := get_user_rating(:NEW.UserId);
    score := calculate_message_rating(:NEW.Text);
    rating_after := rating_before + score;

    update users set Rating = rating_after where UserId = :NEW.UserId;

    log_new_message(:NEW.UserId, :NEW.MessageId, rating_before, rating_after);
end message_ai_trg;

-- Триггер на изменение рейтинга пользователя, заносит информацию в таблицу Results по необходимости
create or replace trigger users_rate_update_au_trg
    after update on users for each row
begin
    if (:OLD.Rating is null or :NEW.Rating is null or :OLD.UserId is null or :NEW.UserId is null or :OLD.UserId != :NEW.UserId) then
        return;
    end if;

    if ((:OLD.Rating < 100 and :NEW.Rating>=100) or (:OLD.Rating > -100 and :NEW.Rating <= -100)) then
        insert into results(UserId, Rating, DateTime) VALUES (:NEW.UserId, :NEW.Rating, systimestamp);
    end if;
end users_rate_update_au_trg;

-- Триггер на создание пользователя, логирует информацию
create or replace trigger users_new_user_ai_trg
    after insert on users for each row
begin
    log_user_added(:NEW.UserId, :NEW.Rating);
end users_new_user_ai_trg;

-- Триггер на удаление пользователя, логирует информацию
create or replace trigger users_remove_user_ad_trg
    after delete on users for each row
begin
    log_user_added(:OLD.UserId, :OLD.Rating);
end users_remove_user_ad_trg;

-- Триггер на добавление друзей, изменяет рейтинг пользователей, ставших друзьями, логирует информацию
create or replace trigger friend_ai_trg
    after insert on friends for each row
declare
    friend1_rating number;
    friend1_new_rating number;
    friend2_rating number;
    friend2_new_rating number;
begin
    friend1_rating := get_user_rating(:NEW.Friend1);
    friend2_rating := get_user_rating(:NEW.Friend2);

    friend1_new_rating := friend1_rating + sign(friend2_rating);
    friend2_new_rating := friend2_rating + sign(friend1_rating);

    if (friend1_rating != friend1_new_rating) then
        update users set Rating = friend1_new_rating where UserId = :NEW.Friend1;
    end if;

    if (friend2_rating != friend2_new_rating) then
        update users set Rating = friend2_new_rating where UserId = :NEW.Friend2;
    end if;

    log_users_friendship(:NEW.Friend1, :NEW.Friend2, friend1_rating, friend1_new_rating, friend2_rating, friend2_new_rating);
end friend_ai_trg;

-- Триггер на добавление пользователя в группу, изменяет рейтинг пользователя и группы, логирует информацию
create or replace trigger usergroups_ai_trg
    after insert on UserGroups for each row
declare
    user_rating_before number;
    user_rating_after number;

    group_rating_before number;
    group_rating_after number;
begin
    user_rating_before := get_user_rating(:NEW.UserId);
    group_rating_before := get_group_rating(:NEW.GroupId);

    user_rating_after := user_rating_before + sign(group_rating_before);
    group_rating_after := group_rating_before + sign(user_rating_before);

    if (user_rating_before != user_rating_after) then
        update users set Rating = user_rating_after where UserId = :NEW.UserId;
    end if;

    if (group_rating_before != group_rating_after) then
        update groups set Rating = group_rating_after where GroupId = :NEW.GroupId;
    end if;

    log_user_added_to_group(:NEW.UserId, :NEW.GroupId, user_rating_before, user_rating_after);
end usergroups_ai_trg;

