create database zomato_1;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup (userid, gold_signup_date) 
VALUES
    (1, '2017-09-22'),
    (3, '2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 
INSERT INTO users(userid, signup_date)
VALUES
    (1, '2014-09-02'),
    (2, '2015-01-15'),
    (3, '2014-04-11');
drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 
INSERT INTO sales(userid, created_date, product_id) 
VALUES
    (1, '2017-04-19', 2),
    (3, '2019-12-18', 1),
    (2, '2020-07-20', 3),
    (1, '2019-10-23', 2),
    (1, '2018-03-19', 3),
    (3, '2016-12-20', 2),
    (1, '2016-11-09', 1),
    (1, '2016-05-20', 3),
    (2, '2017-09-24', 1),
    (1, '2017-03-11', 2),
    (1, '2016-03-11', 1),
    (3, '2016-11-10', 1),
    (3, '2017-12-07', 2),
    (3, '2016-12-15', 2),
    (2, '2017-11-08', 2),
    (2, '2018-09-10', 3);
drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 
INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330); 

select * from sales;
select * from goldusers_signup;
select * from users;
select * from product;

-- 1. what is the total amount each user spent on zomato?
select a.userid, sum(b.price) as total_sale from 
sales a inner join product b 
on a.product_id=b.product_id
group by a.userid;

-- 2.How many days each user visited zomato?
select userid,count(distinct created_date) as no_visits
 from sales group by userid;

-- 3.What was the first product purchased by each customer?
 select * from 
 (select *, RANK() OVER 
    (PARTITION BY userid
    ORDER BY created_date asc)
 AS rank_alias from sales) a where rank_alias=1;
 
-- 4. What was the most purchased item and how many times was it purchased by all customers?
select userid, count(product_id)  as cnt from sales where product_id= (select product_id as cnt  from sales 
group by product_id 
order by cnt desc
 limit 1)  group by userid ;

-- 5.which item was most popular for each customer
select* from (select *, rank() over( partition by userid order by cnt desc) rnk from (
select userid, product_id, count(product_id) as cnt from sales
 group by userid,product_id order by cnt desc) a) b where rnk=1 ;
-- alternate 
select * from(select userid, product_id,count(product_id) as cnt, 
rank() over(partition by userid order by count(product_id) desc) rnk  from sales group by userid, product_id) a 
 where rnk=1;
-- 6 Which item was purchased first by the customer after they became a member?
select * from( select t1.*,rank() over(partition by userid order by created_date) rnk
 from  (select a.userid,a.created_date, a.product_id,b.gold_signup_date 
 from sales a inner join goldusers_signup b 
on a.userid=b.userid where a.created_date >b.gold_signup_date) t1) t2 where rnk=1 ;
-- alternative 
select  * from 
 (select a.userid,a.created_date, a.product_id,b.gold_signup_date,
 rank() over(partition by userid order by created_date) rnk from sales a inner join goldusers_signup b 
on a.userid=b.userid where a.created_date >b.gold_signup_date) t1 where rnk=1 ;
-- 7. which item was puchased just before the customer became a member ?
select * from (select a.userid,a.product_id,a.created_date,b.gold_signup_date,
rank() over(partition by userid order by created_date desc) rnk from sales a inner join  goldusers_signup b
on a.userid=b.userid where a.created_date <b.gold_signup_date) t where rnk=1;

-- 8. total number of orders and amount spent by each customer before they become a member
select userid, count(userid),sum(price) from
(select t1.*,t2.price from (select a.userid,a.product_id,a.created_date,b.gold_signup_date,
rank() over(partition by userid order by created_date desc) rnk from sales a inner join  goldusers_signup b
on a.userid=b.userid where a.created_date <b.gold_signup_date) t1 inner join product t2
 where t1.product_id=t2.product_id) t3 
group by userid	  ;

-- 9 if buyig each product generates zomato points. eg 5rs = 2 zomato points
-- and each product has diff purchasing points,p1 5rs=1 , p2 10rs= 5, p3 5rs=1 zomato points respectively
-- calculate points for each user and for whcih product most poits have been given till now

select userid, sum(total_points)*2.5 as total_money_earned from 
(select e.*,amt/points as total_points from
(select d.*, case when product_id=1 then 5  when product_id=2 then 1 when product_id=3 then 5 else 0 end as points 
 from (select c.userid,c.product_id,sum(price) as amt from
 (select a.*,b.price from sales a inner join product b on a.product_id=b.product_id) c 
 group by userid,product_id) d)e) f group by userid  ;
 
 select* from (select *,rank() over(order  by total_points_earned desc) rnk from (select product_id, sum(total_points) as total_points_earned from 
(select e.*,amt/points as total_points from
(select d.*, case when product_id=1 then 5  when product_id=2 then 1 when product_id=3 then 5 else 0 end as points 
 from (select c.userid,c.product_id,sum(price) as amt from
 (select a.*,b.price from sales a inner join product b on a.product_id=b.product_id) c 
 group by userid,product_id) d)e) f group by product_id)f1)g where rnk=1   ;
 
 -- In the first one year after a customer joins the gold program (including their join date),
 -- irrespective of what the customer has purchased, they
 -- earn 5 Zomato points for every 10 Rs spent. Who earned more, user 1 or user 3,
 -- and what were their points earnings in their first year?
 
 select c.*,d.price*0.5 from(select a.userid,a.created_date, a.product_id,b.gold_signup_date 
 from sales a inner join goldusers_signup b 
on a.userid=b.userid where a.created_date >b.gold_signup_date 
and created_date<=DATE_ADD(gold_signup_date, INTERVAL 1 YEAR))c inner join 
product d where c. product_id=d.product_id;

-- 11. rank all transactions 
select *,rank() over (partition by userid order by created_date) rnk from sales;

-- 12. rank all transaction for each zomato member whenever they are a zomato member,
-- for non members mark na
select  e.*, case when rnk=0 then 'na'else rnk end as rnkk from
(select c.*,cast(case when gold_signup_date is null then 0 else
rank()over(partition by userid order by created_date desc) end AS char(20)) as rnk from
(select a.userid,a.created_date, a.product_id,b.gold_signup_date 
 from sales a left join goldusers_signup b 
on a.userid=b.userid and a.created_date >=b.gold_signup_date)c)e  ;
