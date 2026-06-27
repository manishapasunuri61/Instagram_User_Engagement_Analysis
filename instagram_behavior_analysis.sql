-- creating table 
drop table if exists user_behavior
create table user_behavior (
user_id INTEGER PRIMARY KEY,
age INTEGER,
gender VARCHAR(20),
urban_rural VARCHAR(20),
income_level VARCHAR(20),
employment_status VARCHAR(50),
exercise_hours_per_week NUMERIC(4,1),
sleep_hours_per_night NUMERIC(3,1),
diet_quality VARCHAR(20),
perceived_stress_score INTEGER,
daily_active_minutes_instagram NUMERIC(6,1),
sessions_per_day INTEGER,
posts_created_per_week INTEGER,
reels_watched_per_day INTEGER,
stories_viewed_per_day INTEGER,
likes_given_per_day INTEGER,
comments_written_per_day INTEGER,
dms_sent_per_week INTEGER,
dms_received_per_week INTEGER,
ads_viewed_per_day INTEGER,
ads_clicked_per_day INTEGER,
time_on_feed_per_day NUMERIC(6,1),
time_on_explore_per_day NUMERIC(6,1),
time_on_messages_per_day NUMERIC(6,1),
time_on_reels_per_day NUMERIC(6,1),
uses_premium_features VARCHAR(5),
notification_response_rate NUMERIC(3,2),
last_login_date DATE,
average_session_length_minutes NUMERIC(5,1),
content_type_preference VARCHAR(20),
preferred_content_theme VARCHAR(20),
privacy_setting_level VARCHAR(20),
linked_accounts_count INTEGER,
subscription_status VARCHAR(20)
);

select count(*) from user_behavior


-- Business Metrics Layer:
-- Create a reusable view containing analysis-ready columns and key business metrics.
drop view if exists user_metrics
CREATE VIEW user_metrics AS
SELECT

-- User Identifier
user_id,

-- Demographics
age,
gender,
employment_status,

-- Lifestyle
sleep_hours_per_night,
exercise_hours_per_week,
perceived_stress_score,

-- Platform Behavior
sessions_per_day,
daily_active_minutes_instagram,
average_session_length_minutes,
time_on_feed_per_day,
time_on_explore_per_day,
time_on_messages_per_day,
time_on_reels_per_day,

-- Content & Engagement
posts_created_per_week,
likes_given_per_day,
comments_written_per_day,
dms_sent_per_week,
content_type_preference,
preferred_content_theme,

-- Retention & Trust
notification_response_rate,
last_login_date,
uses_premium_features,
subscription_status,
privacy_setting_level,

-- Meaningful Engagement (ME)
round(((1*likes_given_per_day)+(2*comments_written_per_day)
+(3*(posts_created_per_week/7.0))+(4*(dms_sent_per_week/7.0))),2) as me,

-- Attention (Total Time Spent)
(time_on_feed_per_day + time_on_reels_per_day + time_on_explore_per_day + time_on_messages_per_day) AS attention,

-- Engagement Quality Efficiency (EQE)
round((
(1*likes_given_per_day)+(2*comments_written_per_day)
+(3*(posts_created_per_week/7.0))+(4*(dms_sent_per_week/7.0))
)::NUMERIC
/ 
NULLIF((time_on_feed_per_day + time_on_reels_per_day + time_on_explore_per_day + time_on_messages_per_day),0),2) AS eqe
FROM user_behavior;

select * from user_metrics


-- SECTION 1: PLATFORM BEHAVIOR ANALYSIS

/* Query 1
Insight Objective: Analyze whether session frequency influences Engagement Quality Efficiency (EQE).
Business Question: Do users who visit Instagram more frequently generate healthier engagement? */

with sessions_cte as (
select 
  case when sessions_per_day between 1 and 5 then 'Light Users'
       when sessions_per_day between 6 and 15 then 'Moderate Users'
       when sessions_per_day between 16 and 30 then 'Heavy Users'
  else 'Power Users'
  end as session_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by session_group) 
select * from sessions_cte
order by
  case
     when session_group = 'Light Users' then 1
     when session_group = 'Moderate Users' then 2
     when session_group = 'Heavy Users' then 3
     else 4
end;


/* Query 2
Insight Objective: Analyze whether session duration influences Engagement Quality Efficiency (EQE).
Business Question: Do longer Instagram sessions improve meaningful engagement or lead to passive usage? */

with session_length as (
select 
   case when average_session_length_minutes between 5 and 10 then 'Short Sessions'
        when average_session_length_minutes between 11 and 20 then 'Moderate Sessions'
		when average_session_length_minutes between 21 and 30 then 'Long Sessions'
   else 'Very Long Session'
   end as session_length_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by session_length_group)
select * from session_length
order by 
  case 
     when session_length_group = 'Short Sessions' then 1
     when session_length_group = 'Moderate Sessions' then 2
     when session_length_group = 'Long Sessions' then 3
     else 4
end;


/* Query 3
Insight Objective: Analyze whether overall daily Instagram usage influences Engagement Quality Efficiency (EQE).
Business Question: Does spending more time on Instagram improve or weaken engagement quality? */

with active_minutes as (
select
  case when daily_active_minutes_instagram between 5 and 30 then 'Casual Usage'
       when daily_active_minutes_instagram between 31 and 60 then 'Standard Usage'
	   when daily_active_minutes_instagram between 61 and 120 then 'High Usage'
  else 'Excessive Usage'
	   end as active_minutes_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by active_minutes_group)
select * from active_minutes
order by 
    case when active_minutes_group = 'Casual Usage' then 1
       when active_minutes_group = 'Standard Usage' then 2
	   when active_minutes_group = 'High Usage' then 3
	   else 4
end;


/* Query 4 
Insight Objective: Analyze whether Feed consumption influences Engagement Quality Efficiency (EQE).
Business Question: Does Feed usage encourage meaningful engagement or passive scrolling? */

with feed_time as (
select
  case when time_on_feed_per_day between 2 and 15 then 'Quick Feed Users'
       when time_on_feed_per_day between 16 and 30 then 'Balanced Feed Users'
       when time_on_feed_per_day between 31 and 60 then 'Feed Focused Users'
       else 'Feed Immersed Users'
end as feed_time_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by feed_time_group)
select * from feed_time
order by
  case
    when feed_time_group = 'Quick Feed Users' then 1
    when feed_time_group = 'Balanced Feed Users' then 2
    when feed_time_group = 'Feed Focused Users' then 3
  else 4
end;


/* Query 5
Insight Objective: Analyze whether Reels consumption influences Engagement Quality Efficiency (EQE).
Business Question: Does increased short-form video consumption improve engagement quality? */

with reels_time as (
select
  case when time_on_reels_per_day between 1 and 15 then 'Quick Reel Viewers'
       when time_on_reels_per_day between 16 and 30 then 'Regular Reel Viewers'
       when time_on_reels_per_day between 31 and 60 then 'Reel Enthusiasts'
  else 'Reel Immersed Viewers'
end as reels_time_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by reels_time_group)
select * from reels_time
order by
  case when reels_time_group = 'Quick Reel Viewers' then 1
       when reels_time_group = 'Regular Reel Viewers' then 2
       when reels_time_group = 'Reel Enthusiasts' then 3
  else 4
end;



-- SECTION 2: CONTENT & ENGAGEMENT ANALYSIS

/* Query 1
Insight Objective: Analyze whether content creation influences Engagement Quality Efficiency (EQE).
Business Question: Do users who create more posts achieve healthier engagement? */

with posting_activity as (
select 
  case when posts_created_per_week = 0 then 'Non Posters'
       when posts_created_per_week between 1 and 3 then 'Light Posters'
       when posts_created_per_week between 4 and 7 then 'Regular Posters'
  else 'Frequent Posters'
end as posting_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by posting_group)
select * from posting_activity
order by
   case when posting_group = 'Non Posters' then 1
        when posting_group = 'Light Posters' then 2
        when posting_group = 'Regular Posters' then 3
   else 4
end;


/* Query 2
Insight Objective: Analyze whether commenting behavior influences Engagement Quality Efficiency (EQE).
Business Question: Do users who comment more generate healthier engagement? */

with commenting_activity as (
select 
 case when comments_written_per_day between 4 and 10 then 'Light Commenters'
      when comments_written_per_day between 11 and 25 then 'Active Commenters'
      when comments_written_per_day between 26 and 50 then 'Engaged Commenters'
 else 'Conversation Starters'
end as commenting_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by commenting_group)
select * from commenting_activity
order by
  case when commenting_group = 'Light Commenters' then 1
       when commenting_group = 'Active Commenters' then 2
       when commenting_group = 'Engaged Commenters' then 3
  else 4
end;


/* Query 3
Insight Objective: Analyze whether private messaging influences Engagement Quality Efficiency (EQE).
Business Question: Do stronger private social interactions improve engagement quality? */

with dm_activity as (
select 
  case when dms_sent_per_week between 7 and 15 then 'Casual Connectors'
       when dms_sent_per_week between 16 and 25 then 'Regular Connectors'
       when dms_sent_per_week between 26 and 40 then 'Active Connectors'
  else 'Strong Connectors'
end as dm_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by dm_group)
select * from dm_activity
order by
  case when dm_group = 'Casual Connectors' then 1
       when dm_group = 'Regular Connectors' then 2
       when dm_group = 'Active Connectors' then 3
  else 4
end;


/* Query 4
Insight Objective: Analyze whether preferred content formats influence Engagement Quality Efficiency (EQE).
Business Question: Which content format is associated with healthier engagement? */

select content_type_preference, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by content_type_preference
order by content_type_preference


/* Query 5
Insight Objective: Analyze whether preferred content themes influence Engagement Quality Efficiency (EQE).
Business Question: Which content themes are associated with healthier engagement? */

select preferred_content_theme, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by preferred_content_theme
order by preferred_content_theme



-- SECTION 3: LIFESTYLE ANALYSIS

/* Query 1
Insight Objective: Analyze whether sleep habits influence Engagement Quality Efficiency (EQE).
Business Question: Do users with healthier sleep habits achieve better engagement quality? */

with sleep_activity as (
select
  case when sleep_hours_per_night between 3 and 5 then 'Low Sleep'
       when sleep_hours_per_night between 6 and 8 then 'Healthy Sleep'
  else 'Extended Sleep'
end as sleep_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by sleep_group)
select *
from sleep_activity
order by 
  case when sleep_group = 'Low Sleep' then 1
       when sleep_group = 'Healthy Sleep' then 2
  else 3
end;


/* Query 2
Insight Objective: Analyze whether physical activity influences Engagement Quality Efficiency (EQE).
Business Question: Do physically active users demonstrate healthier engagement? */

with exercise_activity as (
select
  case when exercise_hours_per_week between 0 and 3 then 'Low Activity'
     when exercise_hours_per_week between 4 and 8 then 'Moderate Activity'
     when exercise_hours_per_week between 9 and 14 then 'Active Lifestyle'
  else 'Highly Active'
end as exercise_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by exercise_group)
select * from exercise_activity
order by
  case when exercise_group = 'Low Activity' then 1
       when exercise_group = 'Moderate Activity' then 2
       when exercise_group = 'Active Lifestyle' then 3
  else 4
end;


/* Query 3
Insight Objective: Analyze whether stress levels influence Engagement Quality Efficiency (EQE).
Business Question: Does increasing stress affect engagement quality? */

with stress_activity as (
select
  case when perceived_stress_score between 0 and 10 then 'Low Stress'
       when perceived_stress_score between 11 and 20 then 'Moderate Stress'
       when perceived_stress_score between 21 and 30 then 'High Stress'
  else 'Very High Stress'
end as stress_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by stress_group)
select * from stress_activity
order by
  case when stress_group = 'Low Stress' then 1
       when stress_group = 'Moderate Stress' then 2
      when stress_group = 'High Stress' then 3
  else 4
end;



-- SECTION 4: RETENTION & TRUST ANALYSIS

/* Query 1
Insight Objective: Analyze whether notification responsiveness influences Engagement Quality Efficiency (EQE).
Business Question: Do users who respond to notifications more frequently achieve healthier engagement? */

with notification_activity as (
select
  case when notification_response_rate <= 0.25 then 'Low Responders'
       when notification_response_rate <= 0.50 then 'Moderate Responders'
       when notification_response_rate <= 0.75 then 'Active Responders'
  else 'Highly Responsive'
end as notification_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by notification_group)
select * from notification_activity
order by
  case when notification_group = 'Low Responders' then 1
       when notification_group = 'Moderate Responders' then 2
       when notification_group = 'Active Responders' then 3
  else 4
end;


/* Query 2
Insight Objective: Analyze whether premium feature adoption influences Engagement Quality Efficiency (EQE).
Business Question: Do premium feature users demonstrate healthier engagement? */

select uses_premium_features, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by uses_premium_features


/* Query 3
Insight Objective: Analyze whether privacy preferences influence Engagement Quality Efficiency (EQE).
Business Question: Do different privacy settings influence engagement quality? */

select privacy_setting_level, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by privacy_setting_level



-- SECTION 5: DEMOGRAPHICS ANALYSIS

/* Query 1
Insight Objective: Analyze whether age influences Engagement Quality Efficiency (EQE).
Business Question: Which age groups demonstrate healthier engagement? */

with age_activity as (
select
  case when age between 13 and 17 then 'Teen Users'
       when age between 18 and 24 then 'Young Adults'
       when age between 25 and 44 then 'Adults'
  else 'Experienced Adults'
end as age_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by age_group)
select * from age_activity
order by
  case when age_group = 'Teen Users' then 1
       when age_group = 'Young Adults' then 2
       when age_group = 'Adults' then 3
  else 4
end;


/* Query 2
Insight Objective: Analyze whether employment status influences Engagement Quality Efficiency (EQE).
Business Question: Do different employment groups demonstrate different engagement behaviors? */

select employment_status, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by employment_status


/* Query 3
Insight Objective: Analyze whether gender influences Engagement Quality Efficiency (EQE).
Business Question: Does engagement quality differ across genders? */

select gender, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_metrics
group by gender




-- SECTION 6: USER COMBINATION ANALYSIS

/* 6. Business Question: Which combinations of user behaviors drive healthy engagement, passive consumption and dormancy risk?
Reason: Single variable analysis identified the strongest EQE drivers. Create reusable user segments once and use them throughout combination analysis and Tableau dashboards. */

/* Create reusable segments view
Reason: Combination analysis uses the same user buckets repeatedly. */

drop view if exists user_segments
create view user_segments as
select
 user_id, me, Attention, eqe, sessions_per_day, daily_active_minutes_instagram, time_on_feed_per_day, time_on_reels_per_day, 
 perceived_stress_score, notification_response_rate, last_login_date,

-- Session buckets
case
when sessions_per_day between 1 and 5 then 'Light Users'
when sessions_per_day between 6 and 15 then 'Moderate Users'
when sessions_per_day between 16 and 30 then 'Heavy Users'
else 'Power Users'
end as session_group,


-- Daily active minutes buckets
case
when daily_active_minutes_instagram between 5 and 30 then 'Casual Usage'
when daily_active_minutes_instagram between 31 and 60 then 'Standard Usage'
when daily_active_minutes_instagram between 61 and 120 then 'High Usage'
else 'Excessive Usage'
end as active_minutes_group,


-- Feed buckets
case
when time_on_feed_per_day between 2 and 15 then 'Quick Feed Users'
when time_on_feed_per_day between 16 and 30 then 'Balanced Feed Users'
when time_on_feed_per_day between 31 and 60 then 'Feed Focused Users'
else 'Feed Immersed Users'
end as feed_group,


-- Reels buckets
case
when time_on_reels_per_day between 1 and 15 then 'Quick Reel Viewers'
when time_on_reels_per_day between 16 and 30 then 'Regular Reel Viewers'
when time_on_reels_per_day between 31 and 60 then 'Reel Enthusiasts'
else 'Reel Immersed Viewers'
end as reels_group,


-- Stress buckets
case
when perceived_stress_score between 0 and 10 then 'Low Stress'
when perceived_stress_score between 11 and 20 then 'Moderate Stress'
when perceived_stress_score between 21 and 30 then 'High Stress'
else 'Very High Stress'
end as stress_group,


-- Notification buckets
case
when notification_response_rate <= 0.25 then 'Low Responders'
when notification_response_rate <= 0.50 then 'Moderate Responders'
when notification_response_rate <= 0.75 then 'Active Responders'
else 'Highly Responsive'
end as notification_group

from user_metrics;


-- COMBINATIONS

/* Query 1: sessions_per_day + time_on_feed_per_day vs EQE
Insight Objective: Analyze how session frequency and Feed consumption together influence Engagement Quality Efficiency (EQE).
Business Question: Which user combinations indicate healthy engagement or passive consumption? */

select session_group, feed_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_segments
group by session_group, feed_group
order by 
case
when session_group='Light Users' then 1
when session_group='Moderate Users' then 2
when session_group='Heavy Users' then 3
else 4
end,

case
when feed_group='Quick Feed Users' then 1
when feed_group='Balanced Feed Users' then 2
when feed_group='Feed Focused Users' then 3
else 4
end,

avg_eqe desc;


/* Query 2: time_on_reels_per_day + perceived_stress_score vs EQE
Insight Objective: Analyze how Reels consumption and stress levels together influence Engagement Quality Efficiency (EQE).
Business Question: Which user combinations indicate healthy engagement or potential doom-scrolling behavior? */

select reels_group, stress_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_segments
group by reels_group, stress_group
order by
case
when reels_group='Quick Reel Viewers' then 1
when reels_group='Regular Reel Viewers' then 2
when reels_group='Reel Enthusiasts' then 3
else 4
end,

case
when stress_group='Low Stress' then 1
when stress_group='Moderate Stress' then 2
when stress_group='High Stress' then 3
else 4
end,

avg_eqe desc;


/* Query 3: sessions_per_day + daily_active_minutes_instagram vs EQE
Insight Objective: Analyze how session frequency and overall platform usage together influence Engagement Quality Efficiency (EQE).
Business Question: Which user combinations indicate healthy engagement or excessive platform usage? */

select session_group, active_minutes_group, count(*) as total_users, round(avg(eqe),2) as avg_eqe
from user_segments
group by session_group, active_minutes_group
order by
case
when session_group='Light Users' then 1
when session_group='Moderate Users' then 2
when session_group='Heavy Users' then 3
else 4
end,

case
when active_minutes_group='Casual Usage' then 1
when active_minutes_group='Standard Usage' then 2
when active_minutes_group='High Usage' then 3
else 4
end,

avg_eqe desc;


/* Query 4: Dormancy Risk User Identification
Insight Objective: Identify users at risk of becoming dormant using activity frequency, notification responsiveness, and login recency.
Business Question: Which users should be prioritized for retention interventions? */

with max_date as (
select max(last_login_date) as latest_login_date
from user_segments
)
select case when session_group = 'Light Users'
       and notification_group = 'Low Responders'
	   and latest_login_date-last_login_date > 30 then 'Dormancy Risk Users'
	   else 'Active Users'
	   end as user_status,
count(*) as total_users, round((count(*)*100.0)/sum(count(*)) over(),2) as percent_of_users
from user_segments cross join max_date
group by user_status;



-- SUPPORTING METRICS

/* Insight Objective: Calculate supporting platform health metrics that complement Engagement Quality Efficiency (EQE).
Business Question: How healthy is the overall Instagram ecosystem in terms of conversations, private interactions, advertisement engagement, and advertisement exposure? */

select round(avg(comments_written_per_day::numeric / nullif(likes_given_per_day,0)),2) as comment_to_like_ratio,
       round(avg((dms_sent_per_week + dms_received_per_week)/7.0),2) as dm_activity_ratio,

	   round(avg(ads_clicked_per_day::numeric/nullif(ads_viewed_per_day,0)),2) as ad_ctr_proxy,
       round(avg(ads_viewed_per_day::numeric/nullif(time_on_feed_per_day+time_on_reels_per_day+time_on_explore_per_day
              +time_on_messages_per_day,0)),2) as ad_load_proxy
	   
from user_behavior;


/* Dashboard 1 KPI Query
Insight Objective: Summarize the overall engagement health of the Instagram platform.
Business Question: What is the total user base, and what is the average Engagement Quality Efficiency (EQE) across all users? */

select count(*) as total_users, round(avg(eqe),2) AS avg_eqe from user_metrics;
