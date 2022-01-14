/*

 Drop all tables

 */

drop table KeyWords purge;
drop table results purge;
drop table logs purge;
drop table friends purge;
drop table messages purge;
drop table UserGroups purge;
drop table groups purge;
drop table users purge;

/*

 Drop all functions

 */

drop function calculate_message_rating;
drop function get_group_rating;
drop function get_user_rating;

/*

 Drop all procedures

 */

drop procedure log_new_message;
drop procedure log_user_added;
drop procedure log_user_added_to_group;
drop procedure log_user_deleted;
drop procedure log_users_friendship;


/*
 Check user tables
 */

select * from user_tables;
select * from user_constraints;
select * from user_triggers;
select * from user_sequences;
select * from user_procedures;