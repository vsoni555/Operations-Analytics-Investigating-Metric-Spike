     


--Case Study 1 (Job Data)

--Number of jobs reviewed: Amount of jobs reviewed over time.
-- Calculate the number of jobs reviewed per hour per day for November 2020

select   Date  , count(job_id) as [Jobs/Day], Round(sum(time_spent)/3600,2) as [Hours Spent] 
from  dw.jobs
where date  between '2020-11-01' and '2020-11-30'
group by date
order by date 






--Throughput: It is the no. of events happening per second.
 --Let’s say the above metric is called throughput. 
 --Calculate 7 day rolling average of throughput? For throughput, do you prefer daily metric or 7-day rolling and why?


 select A.*,
 avg(THROUGhPUT) over(partition by JOB_ID order by DATE, date rows between 6 preceding and current row) as Last7Days_Rolling_Avg 
	   from 
	   (
  select  round(COUNT(event)/sum(time_spent),4)  as Throughput , job_id ,CAST(Date AS DATE) AS Date from  dw.jobs
   group  by date , job_id) A
   order by date 



  --Percentage share of each language: Share of each language for different contents.
-- Calculate the percentage share of each language in the last 30 days?


   SELECT Language, count(Language) *100 / sum(count(Language)) OVER () as 'Percentage'
FROM dw.jobs
where date between '2020-11-01' and '2020-11-30'
GROUP BY Language 


   SELECT Language ,  round(count(language)*100.0   / (select count(language) as TotalLanguage from dw.jobs),1) as [Percentage Share]
 from dw.jobs
 group by language 


 --How will you display duplicates from the table?

 select * , ROW_NUMBER() over ( partition by job_id, actor_id order by date ) as Rank  from dw.jobs
 





   -- Investigating Metric Spike 


   --User Engagement: To measure the activeness of a user. Measuring if the user finds quality in a product/service.
   --Calculate the weekly user engagement?

  select count (distinct(user_id)) as [Active Users] from dw.users
 where state IN ('active')


  select count (distinct(user_id)) as [Active Users] from dw.users
 where state IN ('pending')



  select count (distinct(user_id)) as [Total Users] from dw.users
 






 --Weekly user engagement 
 select count (distinct(user_id)) as [User Engagement] , DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(OCcurred_at AS DATE)),0)  as Week from dw.events 
 group by DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(OCcurred_at AS DATE)),0)  
 ORDER BY 2



 --OR 

  select   count(distinct(user_id)) as [Users Engagement]  , datepart( week ,occurred_at) as Week     from dw.events
  group by datepart( week ,occurred_at) 
  order by 2





 -- Weekly Engagement: To measure the activeness of a user. Measuring if the user finds quality in a product/service weekly.
 -- Calculate the weekly engagement per device?
  -- weekly engagement per device 

select  device ,count (distinct(user_id)) as [User Engagement] ,
DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(OCcurred_at AS DATE)),0)  as Week from dw.events 
group by DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(OCcurred_at AS DATE)),0)  , device
ORDER BY  device , week 
 

 -- or 

  select  device  , count(distinct(user_id)) as [Users Engagement]  , datepart( week ,occurred_at) as Week     from dw.events
  group by datepart( week ,occurred_at)  , device 
  order by 1,3


  select  device ,count (distinct(user_id)) as [User Engagement]   ,
DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(OCcurred_at AS DATE)),0)  as Week from dw.events 
group by DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(OCcurred_at AS DATE)),0)  , device
ORDER BY  device , week 



--Amount of users growing over time for a product.
-- Calculate the user growth for product?


select  week,count(distinct(user_id))  as Counts    ,
count(distinct(user_id)) - lag(count(distinct(user_id)),1)  over  (order by week)  as Growth   from
(
 select  user_id , DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(OCcurred_at AS DATE)),0) as Week  from dw.events 
 ) a
 group by Week  


 -- user-signup weekly cohort 
 
select *  from 
(
select users,  signedupweek , DATEDIFF(week, signedupweek,occurred_at)  as  weekssincesignedup   from 
(
select  user_id as users, DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(OCcurred_at AS DATE)),0)   as occurred_at   from dw.events
group by  user_id,DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(OCcurred_at AS DATE)),0)
)a
  ,
  (
  select  min(DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(occurred_at AS DATE)),0))  as signedupweek ,USER_ID
   from     dw.events 
   group by user_id
   ) b
   where a.users=b.user_id
)mm
pivot 
( count(users)
 for weekssincesignedup in( [0],[1]  ,
[2]	 ,
[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18])
)b
order by signedupweek 





 --Email Engagement: Users engaging with the email service.
-- Calculate the email engagement metrics?


 select ACTION , COUNT( ACTION) as [Email Engagements] , MoNTH from 
 (

 select  * , DATEADD(month,DATEDIFF(month, 0,CAST(OCcurred_at AS DATE)),0)  as Month from dw.EMAIL_EVENTS
 )a
 group by ACTION , mONTH
 ORDER BY 2






 ---------------------------------------------------------------------------------------------------------------------






 -- miscellaneous 
 with one as (
SELECT 
  *,
  datepart(MONTH , occurred_at) as month,
  CASE WHEN LEAD (ACTION, 1 ) OVER( PARTITION BY USER_ID ORDER BY OCCURRED_AT ASC )  = 'email_open' THEN 1 ELSE 0 END AS opened_email,
  CASE WHEN LEAD (ACTION, 2 ) OVER( PARTITION BY USER_ID ORDER BY OCCURRED_AT ASC ) = 'email_clickthrough' THEN 1 ELSE 0 END AS clicked_email
FROM
  dw.eMAIL_EVENTS
)
SELECT 
  action,
  month,
  count(action),
  sum(opened_email) as num_open,
  sum(clicked_email) as num_clicked
FROM
  one
WHERE action in ('sent_weekly_digest','sent_reengagement_email')
GROUP BY
  action,
  month
ORDER BY
  action,
  month



  --select * from dw.events
  --where user_id=14032

  --select * from dw.users
  --where user_id=14032


  


select distinct  a.user_id  from 
(
select * from dw.events
where cast(occurred_at as date) between '2014-05-01' and '2014-05-31'

) a
join
( 
select * from dw.users 
where cast(created_at as date) between '2014-05-01' and '2014-05-31' and state in ('active')

) b on a.user_id=b.user_id





   --weekly  user-signup cohort for the  month of may 2014 from the first signed up date 

IF OBJECT_ID('tempdb.dbo.#retetnion') IS NOT NULL DROP TABLE #retention
select * into   #retention  from 
(
select distinct weeksssincesignedup, users , cast(signedupweek as date) as signedupweek from 
(
  select  DATEDIFF(week, signedupweek,occurred_at)  as   weeksssincesignedup    ,*  from 
  (
  select  DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(u.created_at AS DATE)),0)  as signedupweek , u.user_id  as users, e.user_id, 
  DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(e.OCcurred_at AS DATE)),0)   as occurred_at from     dw.events  e   join  dw.users  u 
  on u.user_id=e.user_id 
  where u.state in ('Active') 
 ) m 
 where signedupweek between '2014-05-01' and '2014-05-31'  and occurred_at between '2014-05-01' and '2014-05-31' 

)mm

)mmm

pivot 
( count(users)
 for weeksssincesignedup in( [0],[1]  ,
[2]	 ,
[3])
)b

order by 1 

--user-signup weekly cohort
select* from #retention 

order by 1

-- In percetage 
select  signedupweek ,( 1.0* [0]/[0]*100) as '2014-05-05'  ,
(1.0*[1]/[0]*100 ) as '2014-05-12', (1.0*[2]/[0]*100 )as  '2014-05-19' ,
(1.0* [3]/[0]*100 ) as '2014-05-26' from #retention 
order by 1


--weekly  user-signup cohort  analysis for 4 months data from the first signed up date

select *  from 
(
select distinct weekssincesignedup, users , cast(signedupweek as date) as signedupweek from 
(
  select  DATEDIFF(week, signedupweek,occurred_at)  as  weekssincesignedup    ,*  from 
  (
  select  DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(u.created_at AS DATE)),0)  as signedupweek , u.user_id  as users, e.user_id, 
  DATEADD(WEEK,DATEDIFF(WEEK, 0,CAST(e.OCcurred_at AS DATE)),0)   as occurred_at from     dw.events  e   join  dw.users  u 
  on u.user_id=e.user_id 
  where u.state in ('Active') 
 ) m 
 where signedupweek between 
'2014-05-01' and '2014-08-31'  and occurred_at between '2014-05-01' and '2014-08-31' 

)mm
)mmm
pivot 
( count(users)
 for weekssincesignedup in( [0],[1]  ,
[2]	 ,
[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16])
)b
order by signedupweek 
