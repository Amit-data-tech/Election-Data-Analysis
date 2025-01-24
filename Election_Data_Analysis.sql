use election_data;

--Data Cleaning 
--Replace NULL values in the Sex column with 'NOTA'
update results_2014
set sex = 'NOTA'
where sex is null

update results_2019
set sex = 'NOTA'
where sex is null

--Replace NULL values in the Category column with 'NOTA'
update results_2014
set category = 'NOTA'
where category is null

update results_2019
set category = 'NOTA'
where category is null

--Replace NULL values in the Sex column with 0 as datatype of this column is INT
update results_2014
set age = 0
where age is null

update results_2019
set age = 0
where age is null

--Replace NULL values in the Party_symbol column with 'NOTA'
update results_2019
set party_symbol = 'NOTA'
where party_symbol is null

--Truncate the category from the pc_name column
update results_2014
set pc_name=left(pc_name,len(pc_name)-5)  
where pc_name like '%(SC)'

update results_2019
set pc_name=left(pc_name,len(pc_name)-5)  
where pc_name like '%(SC)'

--Trim leading and trailing spaces from the pc_name column
update results_2014
set pc_name=TRIM(pc_name)  

update results_2019
set pc_name=TRIM(pc_name)  

--Correct spelling mistakes
update results_2014
set pc_name='Jaynagar'
where  pc_name = 'Joynagar'

update results_2014
set pc_name='Dadra And Nagar Haveli'
where  pc_name = 'Dadar & Nagar Haveli'

update results_2014
set pc_name='Bardhawan Durgapur'
where  pc_name = 'Burdwan - durgapur'

-----------------------------------------
--Total Voters
select sum(total_votes) from results_2014

select sum(total_votes) from results_2019

--Total Electors 
select sum(distinct(total_electors)) from results_2014--Distinct function is used as there are repeated values

select sum(distinct(total_electors)) from results_2019

--Total 'NOTA' Votes
select SUM(total_votes) from results_2014
where category = 'NOTA'--Filter data only for Category 'NOTA'

select SUM(total_votes) from results_2019
where category = 'NOTA'

--Total Postal Votes
select SUM(POSTAL_votes) from results_2014

select SUM(POSTAL_votes) from results_2019

--Overall Voters Turnout Ratio
select cast(sum(total_votes)as float)/cast(sum(distinct(total_electors)) as float)*100--Used the CAST function because the data is in INT, and the output will be in FLOAT
from results_2014

select cast(sum(total_votes)as float)/cast(sum(distinct(total_electors)) as float)*100
from results_2019

--Count of FEMALE candidates
select count(*) from results_2014
where sex= 'F'

select count(*) from results_2019
where sex= 'Female'

--Votes Share for the National Parties
with national_party as(  --CTE for Ranking over the total_votes column
select *,rank() over(partition by state,pc_name order by total_votes ) as rnk
from results_2014
where party in ('BJP','INC','BSP','AAAP','NCP','CPI','CPIM')
)
select party,
cast(sum(total_votes)as float)/--Sum of votes secured by each party
(select cast(sum(total_votes)as float)from national_party)*100 as voter_turnout_per--Subquery to calculate the total votes secured by all national parties
from national_party
group by party--Group votes for each party. This will help calculate party-wise votes
order by voter_turnout_per desc

with national_party as(  --CTE for Ranking over the total_votes column
select *,rank() over(partition by state,pc_name order by total_votes ) as rnk
from results_2019
where party in ('BJP','INC','BSP','AAAP','CPIM','npep')
)
select party,
cast(sum(total_votes)as float)/--Sum of votes secured by each party
(select cast(sum(total_votes)as float)from national_party)*100 as voter_turnout_per--Subquery to calculate the total votes secured by all national parties
from national_party
group by party--Group votes for each party. This will help calculate party-wise votes
order by voter_turnout_per desc

--Count of Seats secured by each national party
with national_party as(
select *,rank() over(partition by state,pc_name order by total_votes desc) as rnk
from results_2014
)
select party,count(*)as total_seats from national_party
where rnk = 1 and
party in ('BJP','INC','BSP','AAAP','NCP','CPI','CPIM')
group by party

with national_party as(
select *,rank() over(partition by state,pc_name order by total_votes desc) as rnk
from results_2019
)
select party,count(*)as total_seats from national_party
where rnk = 1 and
party in ('BJP','INC','BSP','AAAP','Npep','CPIM')
group by party

--Gender Distribution of Winners
with national_party as(
select *,rank() over(partition by state,pc_name order by total_votes desc) as rnk
from results_2014
)
select sex,count(*) from national_party
where rnk = 1
group by sex

with national_party as(
select *,rank() over(partition by state,pc_name order by total_votes desc) as rnk
from results_2019
)
select sex,count(*) from national_party
where rnk = 1
group by sex

--Category Distribution of Winners
with national_party as(
select *,rank() over(partition by state,pc_name order by total_votes desc) as rnk
from results_2014
)
select category,count(*) from national_party
where rnk = 1
group by category

with national_party as(
select *,rank() over(partition by state,pc_name order by total_votes desc) as rnk
from results_2019
)
select category,count(*) from national_party
where rnk = 1
group by category

--Voters Turnout Percentage by States
select state, 
cast(sum(total_votes)as float)/cast(sum(distinct(total_electors))as float)*100 as voters_turnout_per
from results_2014
group by state
order by voters_turnout_per desc

select state, 
cast(sum(total_votes)as float)/cast(sum(distinct(total_electors))as float)*100 as voters_turnout_per
from results_2019
group by state
order by voters_turnout_per desc

--Voters Turnout Percentage by Constituency
select state,pc_name,--top/Bottom 10 state,pc_name, 
cast(sum(total_votes)as float)/cast(sum(distinct(total_electors))as float)*100 as voters_turnout_per
from results_2014
group by state,pc_name
order by voters_turnout_per desc

select state,pc_name,--top/Bottom 10 state,pc_name, 
cast(sum(total_votes)as float)/cast(sum(distinct(total_electors))as float)*100 as voters_turnout_per
from results_2019
group by state,pc_name
order by voters_turnout_per desc

--Winning Candidate with the Difference of Votes from the Runner-up
with national_party as(
select *,rank() over(partition by state,pc_name order by total_votes desc) as rnk
from results_2014
)
select
state,pc_name,
max(case when rnk = 1 then candidate end) as top_candidate,--Fetch data where rank is 1, used like a WHERE clause
max(case when rnk = 1 then total_votes end) - max(case when rnk = 2 then total_votes end) as vote_difference--Calculate the difference in votes between the Winner and the Runner-up
from national_party
group by state, pc_name
order by vote_difference desc

with national_party as(
select *,rank() over(partition by state,pc_name order by total_votes desc) as rnk
from results_2019
)
select
state,pc_name,max(case when rnk = 1 then candidate end) as top_candidate,
max(case when rnk = 1 then total_votes end) - max(case when rnk = 2 then total_votes end) as vote_difference
from national_party
group by state, pc_name
order by vote_difference desc



--Votes Share for All Parties
select party,
cast(sum(total_votes)as float)/(select cast(sum(total_votes) as float) from results_2019)*100  as votes_share
from results_2019
group by party
order by votes_share desc

--Seats Secured by Each Parties
with national_party as(
select *,rank() over(partition by state,pc_name order by total_votes desc) as rnk
from results_2019
)
select party,count(*)as total_seats
from national_party
where rnk = 1
group by party
order by total_seats desc

--Constituencies Where 'INC' Increased Its Vote Share
with rf_votes_per as(
select state,pc_name,
cast(sum(total_votes) as float)/--Calculate votes percentage in year 2014
(select sum(total_votes) from results_2014 where state=r.state and pc_name= r.pc_name)*100 as vote_per_2014
from results_2014 as r
where party ='INC'
group by state,pc_name
),
rn_votes_per as(
select state,pc_name,
cast(sum(total_votes) as float)/
(select sum(total_votes) from results_2019 where state=r.state and pc_name= r.pc_name)*100 as vote_per_2019
from results_2019 as r
where party ='INC'
group by state,pc_name
)
select 
rn.state,rn.pc_name,
rf.vote_per_2014,rn.vote_per_2019,
rn.vote_per_2019-rf.vote_per_2014 as per_diff
from rf_votes_per as rf
full join rn_votes_per as rn--Join Both tables
on rf.state=rn.state and
rf.pc_name=rn.pc_name
where rn.vote_per_2019-rf.vote_per_2014 is not null--Handle Null Values
order by per_diff desc

--Constituencies Where 'BJP' Increased Its Vote Share
with rf_votes_per as(
select state,pc_name,
cast(sum(total_votes) as float)/
(select sum(total_votes) from results_2014 where state=r.state and pc_name= r.pc_name)*100 as vote_per_2014
from results_2014 as r
where party ='bjp'
group by state,pc_name
),
rn_votes_per as(
select state,pc_name,
cast(sum(total_votes) as float)/
(select sum(total_votes) from results_2019 where state=r.state and pc_name= r.pc_name)*100 as vote_per_2019
from results_2019 as r
where party ='bjp'
group by state,pc_name
)
select 
rn.state,rn.pc_name,
rf.vote_per_2014,rn.vote_per_2019,
rn.vote_per_2019-rf.vote_per_2014 as per_diff
from rf_votes_per as rf
full join rn_votes_per as rn
on rf.state=rn.state and
rf.pc_name=rn.pc_name
where rn.vote_per_2019-rf.vote_per_2014 is not null
order by per_diff desc

--Constituency Where NOTA Votes Are Highest
select top 1 pc_name,max(total_votes) as votes
from results_2014
where party='NOTA'
group by pc_name
order by votes desc

select top 1 pc_name,max(total_votes) as votes
from results_2019
where party='NOTA'
group by pc_name
order by votes desc


--Constituencies with Consecutively Elected Party
with same_party as (
select  rn.pc_name, rn.party,
rank() over (partition by rn.state, rn.pc_name order by rn.total_votes desc) as rnkn,
rank() over (partition by rf.state, rf.pc_name order by rf.total_votes desc) as rnkf,
cast(rn.total_votes as float) / 
(select sum(rn2.total_votes) 
from results_2019 rn2 
where rn2.state = rn.state and rn2.pc_name = rn.pc_name) * 100 as vote_per_2019
from results_2014 rf
inner join results_2019 rn
on rf.state = rn.state 
and rf.pc_name = rn.pc_name 
and rf.party = rn.party 
and rf.party_symbol = rn.party_symbol
)
select pc_name, party, vote_per_2019
from same_party
where rnkf = 1 AND rnkn = 1
order by vote_per_2019 desc

--Constituencies Where the Elected Party Has Changed
with rf as(
select state,pc_name,party,
rank()over(partition by state, pc_name order by total_votes desc) as rnkf,
cast(total_votes as float)/
(select sum(total_votes) from results_2014 where state=cte_rf.state and pc_name=cte_rf.pc_name)*100 as vote_per_14
from results_2014 as cte_rf),
rn as(
select state,pc_name,party,
rank()over(partition by state, pc_name order by total_votes desc) as rnkn,
cast(total_votes as float)/
(select sum(total_votes) from results_2019 where state=cte_rn.state and pc_name=cte_rn.pc_name)*100 as vote_per_19
from results_2019 as cte_rn)
select rn.state,rn.pc_name,rf.party,rn.party,rf.vote_per_14,rn.vote_per_19
from rf as rf
inner join rn as rn on
rf.state=rn.state and
rf.pc_name=rn.pc_name
where rnkf=1 and rnkn =1 and rf.party!=rn.party
order by rn.vote_per_19 desc


select * from results_2014
select * from results_2019