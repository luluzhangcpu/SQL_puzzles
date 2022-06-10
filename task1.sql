------------------------------------------------------------------------------------------

--Q1 组合两个表,将对应键连接起来，并取相对应的字段；
SELECT p.firstname, p.lastname, a.city, a.state
FROM person p
	LEFT JOIN address a ON a.personid = p.personid;

------------------------------------------------------------------------------------------

--Q2 第二高的薪水，获取并返回 Employee 表中第二高的薪水，若不存在，返回 null;
SELECT MIN(salary) AS SecondHighestSalary
FROM (
	SELECT salary, dense_rank() OVER (ORDER BY salary DESC) AS px
	FROM employee
) e
WHERE px = 2;

------------------------------------------------------------------------------------------

--Q3 第N高的薪水，获取 Employee 表第 n 高的工资，若不存在，返回null;
CREATE FUNCTION getNthHighestSalary (
	N INT
)
RETURNS INT
BEGIN
	RETURN 
		SELECT MIN(salary)
		FROM (
			SELECT salary, dense_rank() OVER (ORDER BY salary DESC) AS px
			FROM employee
		) e
		WHERE px = N;
END

------------------------------------------------------------------------------------------
  
--Q4 分数排名，对分数进行降序排列；
SELECT score, dense_rank() OVER (ORDER BY score DESC)  'rank'
FROM scores;

------------------------------------------------------------------------------------------

--Q5 连续出现的数字：查询所有至少连续出现三次的数字：
SELECT DISTINCT num  ConsecutiveNums
FROM (
	SELECT num
		, CASE 
			WHEN lead(num) OVER (ORDER BY id) = num
			AND lead(num, 2) OVER (ORDER BY id) = num THEN 1
			ELSE 0
		END AS gs
	FROM logs
) l
WHERE gs = 1;

------------------------------------------------------------------------------------------

--Q6 超过经理收入的员工
SELECT e1.name  Employee
FROM employee e1
	JOIN employee e2 ON e1.managerid = e2.id
WHERE e1.salary > e2.salary;

------------------------------------------------------------------------------------------

--Q7 查找重复的电子邮箱
SELECT Email
FROM person
GROUP BY email
HAVING COUNT(*) > 1;

------------------------------------------------------------------------------------------

--Q8 从不订购的客户：查询所有从不订购任何东西
SELECT name Customers
FROM customers c
	LEFT JOIN orders o ON o.customerid = c.id
WHERE o.id IS NULL;

------------------------------------------------------------------------------------------

--Q9 部门工资最高的员工
SELECT d.NAME Department,e.NAME Employee,salary Salary 
FROM
	( SELECT salary, NAME, rank() over ( PARTITION BY departmentid ORDER BY salary DESC ) px, departmentid FROM employee ) e
	LEFT JOIN department d ON d.id = e.departmentid 
WHERE
	e.px = 1;
	
------------------------------------------------------------------------------------------

--Q10 部门工资前三高的所有员工
SELECT dep Department, emp Employee, sal Salary
FROM (
	SELECT d.name dep, e.name emp, salary sal, dense_rank() OVER (PARTITION BY departmentid ORDER BY salary DESC) px
	FROM employee e
		LEFT JOIN department d ON d.id = e.departmentid
) a
WHERE px <= 3;

------------------------------------------------------------------------------------------

--Q11 删除重复电子邮箱(保留最小id）
DELETE FROM person
WHERE id NOT IN (
		SELECT i
		FROM (
			SELECT email, MIN(id) AS i
			FROM person
			GROUP BY email
		) a
	);
	
------------------------------------------------------------------------------------------

--Q12 上升的温度
SELECT id
FROM (
	SELECT id
		, CASE 
			WHEN lag(temperature) OVER (ORDER BY recorddate) < temperature
			AND datediff(recorddate, lag(recorddate) OVER (ORDER BY recorddate)) = 1 THEN 1
			ELSE 0
		END AS px
	FROM weather
) w
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q13 行程和用户
SELECT request_at AS 'Day'
	, round(SUM(CASE 
		WHEN status != 'completed' THEN 1
		ELSE 0
	END) / COUNT(status), 2) AS 'Cancellation Rate'
FROM trips t
	LEFT JOIN users u1 ON u1.users_id = t.client_id
	LEFT JOIN users u2 ON u2.users_id = t.driver_id
WHERE request_at BETWEEN '2013-10-01' AND '2013-10-03'
	AND u1.banned = 'No'
	AND u2.banned = 'No'
GROUP BY request_at;

------------------------------------------------------------------------------------------

--Q14 游戏玩法分析I
SELECT player_id, MIN(event_date) AS first_login
FROM activity
GROUP BY player_id;

------------------------------------------------------------------------------------------

--Q15 游戏玩法分析II
SELECT player_id, device_id
FROM activity a1
WHERE event_date <= ALL (
	SELECT event_date
	FROM activity a2
	WHERE a1.player_id = a2.player_id
);

------------------------------------------------------------------------------------------

--Q16 游戏玩法分析III
SELECT player_id, event_date, SUM(games_played) OVER (PARTITION BY player_id ORDER BY event_date) AS games_played_so_far
FROM activity;

------------------------------------------------------------------------------------------

--Q17 游戏玩法分析IV
SELECT round(SUM(px) / COUNT(DISTINCT player_id), 2) AS fraction
FROM (
	SELECT CASE 
			WHEN datediff(lead(event_date) OVER (PARTITION BY player_id ORDER BY event_date), event_date) = 1
			AND event_date = MIN(event_date) OVER (PARTITION BY player_id ) THEN 1
			ELSE 0
		END AS px, player_id
	FROM activity
) a;

------------------------------------------------------------------------------------------

--Q18 员工薪水中位数
SELECT id, company, salary
FROM (
	SELECT id, company, salary
		, CASE 
			WHEN row_number() OVER (PARTITION BY company ORDER BY salary, id) = round(COUNT(1) OVER (PARTITION BY company ) / 2, 0)
			OR row_number() OVER (PARTITION BY company ORDER BY salary, id) = round((COUNT(1) OVER (PARTITION BY company ) + 1) / 2, 0) THEN 1
			ELSE 0
		END AS px
	FROM employee
) e
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q19 至少有5名直接下属的经理
SELECT e2.name
FROM employee e1
	JOIN employee e2 ON e1.managerid = e2.id
GROUP BY e1.managerid
HAVING COUNT(e1.id) >= 5;

------------------------------------------------------------------------------------------

--Q20 给定数字的频率查询中位数
SELECT round(AVG(num), 1) AS median
FROM (
	SELECT num
		, CASE 
			WHEN SUM(frequency) OVER (ORDER BY num) >= SUM(frequency) OVER () / 2
			AND SUM(frequency) OVER (ORDER BY num DESC) >= SUM(frequency) OVER () / 2 THEN 1
			ELSE 0
		END AS px
	FROM numbers
) n
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q21 当选者
SELECT name
FROM vote v
	LEFT JOIN candidate c ON c.id = v.candidateid
GROUP BY v.candidateid
ORDER BY COUNT(*) DESC
LIMIT 1;

------------------------------------------------------------------------------------------

--Q22 员工奖金
SELECT name, bonus
FROM employee e
	LEFT JOIN bonus b ON b.empid = e.empid
WHERE bonus IS NULL
	OR bonus < 1000;
	
------------------------------------------------------------------------------------------

--Q23 查询回答率最高的问题
SELECT question_id AS survey_log
FROM (
	SELECT question_id, SUM(CASE 
			WHEN action = 'answer' THEN 1
			ELSE 0
		END) / SUM(CASE 
			WHEN action = 'show' THEN 1
			ELSE 0
		END) AS px
	FROM surveylog
	GROUP BY question_id
) s
ORDER BY px DESC, question_id
LIMIT 1;

------------------------------------------------------------------------------------------

--Q24 查询员工的累计薪水
select id,month,sum(salary)over(partition by id order by month range between 2 preceding and current row)'Salary' from(
select id,month,salary,rank()over(partition by id order by month desc)px from employee)e where px != 1 order by id,month desc;

------------------------------------------------------------------------------------------

--Q25 统计各专业学生人数
SELECT dept_name, COUNT(s.student_id) AS student_number
FROM student s
	RIGHT JOIN department d ON d.dept_id = s.dept_id
GROUP BY d.dept_id
ORDER BY student_number DESC, dept_name;

------------------------------------------------------------------------------------------

--Q26 寻找用户推荐人
SELECT name
FROM customer
WHERE referee_id IS NULL
	OR referee_id != 2;
	
------------------------------------------------------------------------------------------

--Q27 2016年的投资
SELECT round(SUM(tiv_2016), 2) AS TIV_2016
FROM (
	SELECT tiv_2016
		, CASE 
			WHEN COUNT(*) OVER (PARTITION BY lat, lon ) = 1
			AND COUNT(*) OVER (PARTITION BY tiv_2015 ) != 1 THEN 1
			ELSE 0
		END AS cs
	FROM insurance
) i
WHERE cs = 1;

------------------------------------------------------------------------------------------

--Q28 订单最多的客户
SELECT customer_number
FROM orders
GROUP BY customer_number
ORDER BY COUNT(*) DESC
LIMIT 1;

------------------------------------------------------------------------------------------

--Q29 大的国家
SELECT name, population, area
FROM world
WHERE population >= 25000000
	OR area >= 3000000;

------------------------------------------------------------------------------------------

--Q30 超过5名学生的课
SELECT class
FROM courses
GROUP BY class
HAVING COUNT(*) >= 5;

------------------------------------------------------------------------------------------

--Q31 好友申请I：总体通过率
SELECT round(ifnull(COUNT(DISTINCT requester_id, accepter_id) / COUNT(DISTINCT sender_id, send_to_id), 0), 2) accept_rate
FROM friendrequest, requestaccepted;

------------------------------------------------------------------------------------------

--Q32 体育馆的人流量
SELECT id, visit_date, people
FROM (
	SELECT id, visit_date, people, COUNT(1) OVER (PARTITION BY px ) AS gs
	FROM (
		SELECT id, visit_date, people
			, CASE 
				WHEN @state - (@state := id) = -1 THEN @cs
				ELSE @cs := @cs + 1
			END AS px
		FROM (
			SELECT id, visit_date, people
			FROM stadium
			WHERE people >= 100
			ORDER BY id
		) p, (
				SELECT @state := 9999, @cs := 0
			) a
	) b
) c
WHERE gs >= 3
ORDER BY visit_date;

------------------------------------------------------------------------------------------

--Q33 好友申请II：
SELECT ri AS id, COUNT(*) AS num
FROM (
	SELECT requester_id AS ri, accepter_id AS ai
	FROM requestaccepted
	UNION
	SELECT accepter_id AS ri, requester_id AS ai
	FROM requestaccepted
) r
GROUP BY ri
ORDER BY COUNT(*) DESC
LIMIT 1;

------------------------------------------------------------------------------------------

--Q34 连续空余座位
SELECT seat_id
FROM (
	SELECT seat_id
		, CASE 
			WHEN lead(seat_id) OVER (ORDER BY seat_id) - seat_id = 1
			OR seat_id - lag(seat_id) OVER (ORDER BY seat_id) = 1 THEN 1
			ELSE 0
		END AS px
	FROM cinema
	WHERE free = 1
) c
WHERE px = 1
ORDER BY seat_id;

------------------------------------------------------------------------------------------

--Q35 销售员
SELECT name
FROM salesperson
WHERE sales_id NOT IN (
	SELECT o.sales_id
	FROM orders o
		LEFT JOIN company c ON c.com_id = o.com_id
	WHERE name = 'RED'
);

------------------------------------------------------------------------------------------

--Q36 树节点
SELECT id
	, CASE 
		WHEN p_id IS NULL THEN 'Root'
		WHEN id IN (
			SELECT p_id
			FROM tree
			WHERE p_id IS NOT NULL
		) THEN 'Inner'
		ELSE 'Leaf'
	END AS Type
FROM tree
ORDER BY id;

------------------------------------------------------------------------------------------

--Q37 判断三角形
SELECT x, y, z
	, CASE 
		WHEN x + y > z
		AND x + z > y
		AND y + z > x THEN 'Yes'
		ELSE 'No'
	END AS triangle
FROM triangle;

------------------------------------------------------------------------------------------

--Q38 平面上的最近距离
SELECT round(sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2)), 2) AS shortest
FROM point2d p1
	JOIN point2d p2
	ON p1.x != p2.x
		OR p1.y != p2.y
ORDER BY shortest
LIMIT 1;

------------------------------------------------------------------------------------------

--Q39 直线上的最近距离
SELECT MIN(p2.x - p1.x) AS shortest
FROM point p1
	JOIN point p2 ON p1.x < p2.x;

------------------------------------------------------------------------------------------

--Q40 二级关注者
SELECT f1.follower, COUNT(DISTINCT f2.follower) AS num
FROM follow f1
	JOIN follow f2 ON f1.follower = f2.followee
GROUP BY f1.follower;

------------------------------------------------------------------------------------------

--Q41 平均工资：部门与公司比较
SELECT yf AS pay_month, department_id, px AS comparison
FROM (
	SELECT yf, department_id
		, CASE 
			WHEN AVG(amount) OVER (PARTITION BY department_id, yf ) > AVG(amount) OVER (PARTITION BY yf ) THEN 'higher'
			WHEN AVG(amount) OVER (PARTITION BY department_id, yf ) < AVG(amount) OVER (PARTITION BY yf ) THEN 'lower'
			ELSE 'same'
		END AS px
	FROM (
		SELECT id, amount, date_format(pay_date, '%Y-%m') AS yf
			, department_id
		FROM salary s
			LEFT JOIN employee e ON e.employee_id = s.employee_id
	) a
) b
GROUP BY yf, department_id;

------------------------------------------------------------------------------------------

--Q42 学生地理信息报告
SELECT MIN(aa) AS 'America', MIN(bb) AS 'Asia'
	, MIN(cc) AS 'Europe'
FROM (
	SELECT name, row_number() OVER (PARTITION BY continent ORDER BY name) AS px
		, CASE 
			WHEN continent = 'America' THEN name
		END AS aa
		, CASE 
			WHEN continent = 'Asia' THEN name
		END AS bb
		, CASE 
			WHEN continent = 'Europe' THEN name
		END AS cc
	FROM student
) s
GROUP BY px
ORDER BY px;

------------------------------------------------------------------------------------------

--Q43 只出现一次的最大数字
SELECT MAX(num) AS num
FROM (
	SELECT num
	FROM mynumbers
	GROUP BY num
	HAVING COUNT(*) = 1
) c;

------------------------------------------------------------------------------------------

--Q44 有趣的电影
SELECT id, movie, description, rating
FROM cinema
WHERE description != 'boring'
	AND id % 2 != 0
ORDER BY rating DESC;

------------------------------------------------------------------------------------------

--Q45 换座位
SELECT id
	, CASE 
		WHEN COUNT(*) OVER () = id
		AND id % 2 != 0 THEN student
		WHEN id % 2 != 0 THEN lead(student) OVER (ORDER BY id)
		ELSE lag(student) OVER (ORDER BY id)
	END AS student
FROM seat;

------------------------------------------------------------------------------------------

--Q46 变更性别
UPDATE salary
SET sex = CASE 
	WHEN sex = 'm' THEN 'f'
	ELSE 'm'
END;

------------------------------------------------------------------------------------------

--Q47 买下所有产品的客户
SELECT customer_id
FROM (
	SELECT customer_id, COUNT(DISTINCT p.product_key) AS cnt
	FROM product p
		LEFT JOIN customer c ON c.product_key = p.product_key
	GROUP BY customer_id
) a
	CROSS JOIN (
		SELECT COUNT(*) AS nt
		FROM product
	) b
WHERE a.cnt = b.nt;

------------------------------------------------------------------------------------------

--Q48 合作过至少三次的演员和导演
SELECT actor_id, director_id
FROM actordirector
GROUP BY actor_id, director_id
HAVING COUNT(*) >= 3;

------------------------------------------------------------------------------------------

--Q49 产品销售分析I
SELECT product_name, year, price
FROM sales s
	LEFT JOIN product p ON p.product_id = s.product_id;

------------------------------------------------------------------------------------------

--Q50 产品销售分析II
SELECT product_id, SUM(quantity) AS total_quantity
FROM sales
GROUP BY product_id;

------------------------------------------------------------------------------------------

--Q51 产品销售分析III
SELECT product_id, year AS first_year, quantity, price
FROM (
	SELECT product_id, year
		, CASE 
			WHEN MIN(year) OVER (PARTITION BY product_id ) = year THEN 1
			ELSE 0
		END AS px, quantity, price
	FROM sales
) s
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q52 项目员工I
SELECT project_id, round(AVG(experience_years), 2) AS average_years
FROM project p
	LEFT JOIN employee e ON p.employee_id = e.employee_id
GROUP BY project_id;

------------------------------------------------------------------------------------------

--Q53 项目员工II
SELECT project_id
FROM (
	SELECT project_id, rank() OVER (ORDER BY cnt DESC) AS px
	FROM (
		SELECT project_id, COUNT(*) AS cnt
		FROM project
		GROUP BY project_id
	) p
) a
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q54 项目员工III
SELECT project_id, employee_id
FROM (
	SELECT project_id, e.employee_id
		, CASE 
			WHEN MAX(experience_years) OVER (PARTITION BY project_id ) = experience_years THEN 1
			ELSE 0
		END AS px
	FROM project p
		LEFT JOIN employee e ON e.employee_id = p.employee_id
) a
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q55 销售分析I
SELECT seller_id
FROM (
	SELECT seller_id, rank() OVER (ORDER BY ze DESC) AS px
	FROM (
		SELECT seller_id, SUM(price) AS ze
		FROM sales
		GROUP BY seller_id
	) a
) b
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q56 销售分析II
SELECT buyer_id
FROM (
	SELECT buyer_id, SUM(CASE 
			WHEN product_name = 'S8' THEN 1
			ELSE 0
		END) AS ss, SUM(CASE 
			WHEN product_name = 'iPhone' THEN 1
			ELSE 0
		END) AS pp
	FROM sales s
		LEFT JOIN product p ON p.product_id = s.product_id
	GROUP BY buyer_id
) a
WHERE ss >= 1
	AND pp = 0;

------------------------------------------------------------------------------------------
	
--Q57 销售分析III
SELECT product_id, product_name
FROM (
	SELECT s.product_id, product_name, SUM(CASE 
			WHEN sale_date < '2019-01-01'
			OR sale_date > '2019-03-31' THEN 1
			ELSE 0
		END) AS cs
	FROM sales s
		LEFT JOIN product p ON p.product_id = s.product_id
	GROUP BY s.product_id, product_name
) a
WHERE cs = 0;

------------------------------------------------------------------------------------------

--Q58 游戏玩法分析V
SELECT event_date AS install_dt, COUNT(px) AS installs
	, round(SUM(cs) / SUM(px), 2) AS Day1_retention
FROM (
	SELECT event_date
		, CASE 
			WHEN rank() OVER (PARTITION BY player_id ORDER BY event_date) = 1 THEN 1
			ELSE 0
		END AS px
		, CASE 
			WHEN rank() OVER (PARTITION BY player_id ORDER BY event_date) = 1
			AND datediff(lead(event_date) OVER (PARTITION BY player_id ORDER BY event_date), event_date) = 1 THEN 1
			ELSE 0
		END AS cs
	FROM activity
) a
WHERE px = 1
GROUP BY event_date;

------------------------------------------------------------------------------------------

--Q59 小众书籍
SELECT book_id, name
FROM (
	SELECT b.book_id, name
		, ifnull(SUM(quantity), 0) AS bs
	FROM books b
		LEFT JOIN orders o
		ON o.book_id = b.book_id
			AND dispatch_date BETWEEN '2018-06-23' AND '2019-06-23'
	WHERE available_from < '2019-05-23'
	GROUP BY b.book_id, name
) a
WHERE bs < 10;

------------------------------------------------------------------------------------------

--Q60 每日新用户统计
SELECT rq AS login_date, COUNT(user_id) AS user_count
FROM (
	SELECT user_id, MIN(activity_date) AS rq
	FROM traffic
	WHERE activity = 'login'
	GROUP BY user_id
) a
WHERE rq BETWEEN '2019-04-01' AND '2019-06-30'
GROUP BY rq
ORDER BY rq;

------------------------------------------------------------------------------------------

--Q61 每位学生的最高成绩
SELECT student_id, course_id, grade
FROM (
	SELECT student_id, course_id, grade, row_number() OVER (PARTITION BY student_id ORDER BY grade DESC, course_id) AS px
	FROM enrollments
) e
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q62 报告的记录
SELECT extra report_reason, COUNT(DISTINCT post_id) report_count
FROM actions
WHERE action = 'report'
	AND action_date = '2019-07-04'
GROUP BY extra;

------------------------------------------------------------------------------------------

--Q63 查询活跃业务
SELECT business_id
FROM (
	SELECT business_id
		, CASE 
			WHEN occurences > AVG(occurences) OVER (PARTITION BY event_type ) THEN 1
			ELSE 0
		END AS pd
	FROM events
) e
GROUP BY business_id
HAVING SUM(pd) >= 2;

------------------------------------------------------------------------------------------

--Q64 用户购买平台
WITH t AS (
		SELECT b AS pf, sdt
		FROM (
			SELECT 'desktop' AS b
			UNION
			SELECT 'mobile' AS b
			UNION
			SELECT 'both'
		) a
			CROSS JOIN (
				SELECT DISTINCT spend_date AS sdt
				FROM spending
			) s
	)
SELECT t.sdt AS spend_date, t.pf AS platform
	, ifnull(SUM(amount), 0) AS total_amount
	, COUNT(DISTINCT user_id) AS total_users
FROM t
	LEFT JOIN (
		SELECT spend_date
			, CASE 
				WHEN COUNT(1) OVER (PARTITION BY spend_date, user_id ) = 2 THEN 'both'
				ELSE platform
			END AS lx, user_id, amount
		FROM spending
	) s
	ON s.spend_date = t.sdt
		AND s.lx = t.pf
GROUP BY t.sdt, t.pf;

------------------------------------------------------------------------------------------

--Q65 报告的记录II
SELECT round(AVG(fb) * 100, 2) AS average_daily_percent
FROM (
	SELECT action_date, SUM(CASE 
			WHEN rid IS NOT NULL THEN 1
			ELSE 0
		END) / COUNT(aid) AS fb
	FROM (
		SELECT a.post_id AS aid, action_date, r.post_id AS rid
		FROM actions a
			LEFT JOIN removals r ON r.post_id = a.post_id
		WHERE extra = 'spam'
		GROUP BY a.post_id, action_date, r.post_id
	) b
	GROUP BY action_date
) c;

------------------------------------------------------------------------------------------

--Q66 查询近30天活跃用户数
SELECT activity_date 'day', COUNT(DISTINCT user_id) active_users
FROM activity
WHERE activity_date BETWEEN '2019-06-28' AND '2019-07-27'
GROUP BY activity_date;

------------------------------------------------------------------------------------------

--Q67 过去30天的用户活动II
SELECT ifnull(round(COUNT(DISTINCT session_id) / COUNT(DISTINCT user_id), 2), 0) average_sessions_per_user
FROM activity
WHERE activity_date BETWEEN '2019-06-28' AND '2019-07-27';

------------------------------------------------------------------------------------------

--Q68 文章浏览I
SELECT DISTINCT author_id id
FROM views
WHERE author_id = viewer_id
ORDER BY id;

------------------------------------------------------------------------------------------

--Q69 文章浏览II
SELECT DISTINCT viewer_id AS id
FROM views
GROUP BY viewer_id, view_date
HAVING COUNT(DISTINCT article_id) >= 2
ORDER BY id;

------------------------------------------------------------------------------------------

--Q70 市场分析I
SELECT user_id AS buyer_id, join_date, COUNT(order_id) AS orders_in_2019
FROM users u
	LEFT JOIN orders o
	ON o.buyer_id = user_id
		AND year(order_date) = 2019
GROUP BY user_id;

------------------------------------------------------------------------------------------

--Q71 市场分析II
SELECT user_id AS seller_id
	, CASE 
		WHEN SUM(px) = 1 THEN 'yes'
		ELSE 'no'
	END AS 2nd_item_fav_brand
FROM (
	SELECT user_id
		, CASE 
			WHEN order_id IS NULL
			OR COUNT(1) OVER (PARTITION BY user_id ) = 1 THEN 0
			WHEN item_brand = favorite_brand
			AND rank() OVER (PARTITION BY user_id ORDER BY order_date) = 2 THEN 1
			ELSE 0
		END AS px
	FROM users u
		LEFT JOIN orders o ON o.seller_id = u.user_id
		LEFT JOIN items i ON i.item_id = o.item_id
) a
GROUP BY user_id;

------------------------------------------------------------------------------------------

--Q72 指定日期的产品价格
SELECT DISTINCT product_id, jg AS price
FROM (
	SELECT p1.product_id
		, CASE 
			WHEN p2.new_price IS NULL THEN 10
			ELSE p2.new_price
		END AS jg, rank() OVER (PARTITION BY p1.product_id ORDER BY p2.change_date DESC) AS px
	FROM products p1
		LEFT JOIN products p2
		ON p1.product_id = p2.product_id
			AND p2.change_date <= '2019-08-16'
) a
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q73 即时食物配送I
SELECT round(SUM(CASE 
		WHEN order_date = customer_pref_delivery_date THEN 1
		ELSE 0
	END) / COUNT(*) * 100, 2) immediate_percentage
FROM delivery;

------------------------------------------------------------------------------------------

--Q74 即时食物配送II
SELECT round(SUM(cs) / SUM(zs) * 100, 2) AS immediate_percentage
FROM (
	SELECT CASE 
			WHEN rank() OVER (PARTITION BY customer_id ORDER BY order_date) = 1 THEN 1
			ELSE 0
		END AS zs
		, CASE 
			WHEN rank() OVER (PARTITION BY customer_id ORDER BY order_date) = 1
			AND order_date = customer_pref_delivery_date THEN 1
			ELSE 0
		END AS cs
	FROM delivery
) d;

------------------------------------------------------------------------------------------

--Q75 重新格式化部门表
SELECT id, SUM(CASE 
		WHEN month = 'Jan' THEN revenue
	END) Jan_Revenue, SUM(CASE 
		WHEN month = 'Feb' THEN revenue
	END) Feb_Revenue
	, SUM(CASE 
		WHEN month = 'Mar' THEN revenue
	END) Mar_Revenue, SUM(CASE 
		WHEN month = 'Apr' THEN revenue
	END) Apr_Revenue
	, SUM(CASE 
		WHEN month = 'May' THEN revenue
	END) May_Revenue, SUM(CASE 
		WHEN month = 'Jun' THEN revenue
	END) Jun_Revenue
	, SUM(CASE 
		WHEN month = 'Jul' THEN revenue
	END) Jul_Revenue, SUM(CASE 
		WHEN month = 'Aug' THEN revenue
	END) Aug_Revenue
	, SUM(CASE 
		WHEN month = 'Sep' THEN revenue
	END) Sep_Revenue, SUM(CASE 
		WHEN month = 'Oct' THEN revenue
	END) Oct_Revenue
	, SUM(CASE 
		WHEN month = 'Nov' THEN revenue
	END) Nov_Revenue, SUM(CASE 
		WHEN month = 'Dec' THEN revenue
	END) Dec_Revenue
FROM department
GROUP BY id;

------------------------------------------------------------------------------------------

--Q76 每月交易I
SELECT yf AS 'month', country, COUNT(amount) AS trans_count
	, SUM(amount) AS trans_total_amount, SUM(ac) AS approved_count
	, SUM(am) AS approved_total_amount
FROM (
	SELECT date_format(trans_date, '%Y-%m') AS yf, country
		, CASE 
			WHEN state = 'approved' THEN amount
			ELSE 0
		END AS am
		, CASE 
			WHEN state = 'approved' THEN 1
			ELSE 0
		END AS ac, amount
	FROM transactions
) t
GROUP BY yf, country;

------------------------------------------------------------------------------------------

--Q77 锦标赛优胜者
SELECT group_id, player_id
FROM (
	SELECT group_id, player_id, rank() OVER (PARTITION BY group_id ORDER BY zj DESC, player_id) AS px
	FROM (
		SELECT player_id, group_id
			, ifnull(SUM(df), 0) AS zj
		FROM players p
			LEFT JOIN (
				SELECT first_player AS pid, first_score AS df
				FROM matches
				UNION ALL
				SELECT second_player AS pid, second_score AS df
				FROM matches
			) m
			ON m.pid = p.player_id
		GROUP BY player_id
	) p
) a
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q78 最后一个能进入电梯的人
SELECT person_name
FROM (
	SELECT person_name, SUM(weight) OVER (ORDER BY turn) AS zs
	FROM queue
) a
WHERE zs <= 1000
ORDER BY zs DESC
LIMIT 1;

------------------------------------------------------------------------------------------

--Q79 每月交易II
SELECT yf AS 'month', country, SUM(CASE 
		WHEN state = 'approved' THEN 1
		ELSE 0
	END) AS approved_count
	, SUM(CASE 
		WHEN state = 'approved' THEN amount
		ELSE 0
	END) AS approved_amount, SUM(CASE 
		WHEN state = 'charged' THEN 1
		ELSE 0
	END) AS chargeback_count
	, SUM(CASE 
		WHEN state = 'charged' THEN amount
		ELSE 0
	END) AS chargeback_amount
FROM (
	SELECT date_format(c.trans_date, '%Y-%m') AS yf, amount, 'charged' AS state
		, country
	FROM chargebacks c
		LEFT JOIN transactions t ON t.id = c.trans_id
	UNION ALL
	SELECT date_format(trans_date, '%Y-%m') AS yf, amount, state
		, country
	FROM transactions
) a
WHERE state IN ('approved', 'charged')
GROUP BY yf, country;

------------------------------------------------------------------------------------------

--Q80 查询结果的质量和占比
SELECT query_name
	, round(AVG(rating / position), 2) quality
	, round(SUM(CASE 
		WHEN rating < 3 THEN 1
		ELSE 0
	END) / COUNT(*) * 100, 2) poor_query_percentage
FROM queries
GROUP BY query_name;

------------------------------------------------------------------------------------------

--Q81 查询球队积分
SELECT team_id, team_name
	, ifnull(SUM(fs), 0) AS num_points
FROM teams t
	LEFT JOIN (
		SELECT host_team AS tid
			, CASE 
				WHEN host_goals > guest_goals THEN 3
				WHEN host_goals = guest_goals THEN 1
				ELSE 0
			END AS fs
		FROM matches
		UNION ALL
		SELECT guest_team AS tid
			, CASE 
				WHEN host_goals < guest_goals THEN 3
				WHEN host_goals = guest_goals THEN 1
				ELSE 0
			END AS fs
		FROM matches
	) m
	ON m.tid = t.team_id
GROUP BY team_id, team_name
ORDER BY num_points DESC, team_id;

------------------------------------------------------------------------------------------

--Q82 报告系统状态的连续日期
with temp as(
    (select fail_date dd,'failed' zt from failed
    where year(fail_date) = 2019
    order by fail_date)
    union all
    (select success_date dd,'succeeded' zt from succeeded
    where year(success_date) = 2019
    order by success_date)
)
select zt period_state,min(dd) start_date,max(dd) end_date from(
select zt,dd,case when datediff(@rq,@rq := dd) = -1 then @cx else @cx := @cx + 1 end px from temp,(select @rq := '2018-01-01',@cx := 0)b)c group by zt,px order by start_date;

------------------------------------------------------------------------------------------

--Q83 每个帖子的评论数
SELECT s1.sub_id post_id, COUNT(DISTINCT s2.sub_id) number_of_comments
FROM submissions s1
	LEFT JOIN submissions s2 ON s1.sub_id = s2.parent_id
WHERE s1.parent_id IS NULL
GROUP BY s1.sub_id;

------------------------------------------------------------------------------------------

--Q84 平均售价
SELECT u.product_id
	, round(SUM(price * units) / SUM(units), 2) AS average_price
FROM unitssold u
	LEFT JOIN prices p
	ON p.product_id = u.product_id
		AND u.purchase_date BETWEEN p.start_date AND p.end_date
GROUP BY u.product_id;

------------------------------------------------------------------------------------------

--Q85 页面推荐
SELECT DISTINCT l1.page_id AS recommended_page
FROM (
	SELECT user1_id AS u1, user2_id AS u2
	FROM friendship
	UNION
	SELECT user2_id AS u1, user1_id AS u2
	FROM friendship
) a
	LEFT JOIN likes l1 ON l1.user_id = a.u2
	LEFT JOIN likes l2
	ON l2.user_id = a.u1
		AND l1.page_id = l2.page_id
WHERE u1 = 1
	AND l2.page_id IS NULL
	AND l1.user_id IS NOT NULL;
	
------------------------------------------------------------------------------------------

--Q86 向公司CEO汇报工作的所有人
SELECT e1.employee_id
FROM employees e1
	LEFT JOIN employees e2 ON e1.manager_id = e2.employee_id
	LEFT JOIN employees e3 ON e2.manager_id = e3.employee_id
WHERE e3.manager_id = 1
	AND e1.employee_id != 1;
	
------------------------------------------------------------------------------------------

--Q87 学生们参加各科测试的次数
SELECT s1.student_id, s1.student_name, s2.subject_name, COUNT(e.subject_name) AS attended_exams
FROM students s1
	CROSS JOIN subjects s2
	LEFT JOIN examinations e
	ON e.student_id = s1.student_id
		AND e.subject_name = s2.subject_name
GROUP BY s1.student_id, s1.student_name, s2.subject_name
ORDER BY s1.student_id, s2.subject_name;

------------------------------------------------------------------------------------------

--Q88 找到连续区间的开始和结束数字
SELECT MIN(log_id) AS start_id, MAX(log_id) AS end_id
FROM (
	SELECT log_id
		, CASE 
			WHEN @iid - (@iid := log_id) = -1 THEN @xh
			ELSE @xh := @xh + 1
		END AS px
	FROM (
		SELECT log_id
		FROM logs
		ORDER BY log_id
	) l, (
			SELECT @iid := 99, @xh := 0
		) a
) b
GROUP BY px
ORDER BY start_id;

------------------------------------------------------------------------------------------

--Q89 不同国家的天气类型
SELECT c.country_name
	, CASE 
		WHEN AVG(weather_state) <= 15 THEN 'Cold'
		WHEN AVG(weather_state) >= 25 THEN 'Hot'
		ELSE 'Warm'
	END weather_type
FROM weather w
	LEFT JOIN countries c ON c.country_id = w.country_id
WHERE day BETWEEN '2019-11-01' AND '2019-11-30'
GROUP BY c.country_id;

------------------------------------------------------------------------------------------

--Q90 求团队人数
SELECT employee_id, COUNT(*) OVER (PARTITION BY team_id ) team_size
FROM employee;

------------------------------------------------------------------------------------------

--Q91 不同性别每日分数总计
SELECT gender, day, SUM(score_points) OVER (PARTITION BY gender ORDER BY day) AS total
FROM scores
ORDER BY gender, day;

------------------------------------------------------------------------------------------

--Q92 餐馆营业额变化增长
select visited_on,zj amount,round(zj/7,2) average_amount from(
select visited_on,sum(rxf)over(order by visited_on range between interval 6 day preceding and current row)zj,lag(rxf,6)over(order by visited_on)qm from(
select visited_on,sum(amount)rxf from customer group by visited_on)a)b where qm is not null;

------------------------------------------------------------------------------------------

--Q93 广告效果
SELECT ad_id
	, ifnull(round(SUM(CASE 
		WHEN action = 'Clicked' THEN 1
		ELSE 0
	END) / SUM(CASE 
		WHEN action IN ('Clicked', 'Viewed') THEN 1
		ELSE 0
	END) * 100, 2), 0) AS ctr
FROM ads
GROUP BY ad_id
ORDER BY ctr DESC, ad_id;

------------------------------------------------------------------------------------------

--Q94 列出指定时间段内所有的下单产品
SELECT product_name, SUM(unit) AS unit
FROM orders o
	LEFT JOIN products p ON p.product_id = o.product_id
WHERE order_date BETWEEN '2020-02-01' AND '2020-02-29'
GROUP BY o.product_id
HAVING SUM(unit) >= 100;

------------------------------------------------------------------------------------------

--Q95 每次访问的交易次数
WITH RECURSIVE num (n) AS (
		SELECT 0 AS a
		UNION
		SELECT n + 1
		FROM num
		WHERE n + 1 <= (
			SELECT COUNT(*)
			FROM transactions
			GROUP BY transaction_date, user_id
			ORDER BY COUNT(*) DESC
			LIMIT 1
		)
	)
SELECT n AS transactions_count, COUNT(cnt) AS visits_count
FROM num
	LEFT JOIN (
		SELECT COUNT(t.amount) AS cnt
		FROM visits v
			LEFT JOIN transactions t
			ON t.user_id = v.user_id
				AND t.transaction_date = v.visit_date
		GROUP BY v.user_id, v.visit_date
	) c
	ON c.cnt = num.n
GROUP BY n
ORDER BY transactions_count;

------------------------------------------------------------------------------------------

--Q96 电影评分
(SELECT name AS results
FROM movierating m
	LEFT JOIN users u ON u.user_id = m.user_id
GROUP BY m.user_id
ORDER BY COUNT(movie_id) DESC, name
LIMIT 1)
UNION
(SELECT title AS results
FROM movierating r
	LEFT JOIN movies m ON m.movie_id = r.movie_id
WHERE date_format(created_at, '%Y-%m') = '2020-02'
GROUP BY r.movie_id
ORDER BY AVG(rating) DESC, title
LIMIT 1);

------------------------------------------------------------------------------------------

--Q97 院系无效的学生
SELECT s.id, s.name
FROM students s
	LEFT JOIN departments d ON d.id = s.department_id
WHERE d.id IS NULL;

------------------------------------------------------------------------------------------

--Q98 活动参与者
SELECT activity
FROM (
	SELECT activity, rank() OVER (ORDER BY cnt) AS px, rank() OVER (ORDER BY cnt DESC) AS jx
	FROM (
		SELECT activity, COUNT(*) AS cnt
		FROM friends
		GROUP BY activity
	) f
) a
WHERE px != 1
	AND jx != 1;
	
------------------------------------------------------------------------------------------

--Q99 顾客的可信联系人数量
SELECT invoice_id, c1.customer_name, price
	, ifnull(COUNT(t.user_id), 0) AS contacts_cnt
	, ifnull(COUNT(c2.customer_id), 0) AS trusted_contacts_cnt
FROM invoices i
	LEFT JOIN customers c1 ON i.user_id = c1.customer_id
	LEFT JOIN contacts t ON t.user_id = i.user_id
	LEFT JOIN customers c2 ON c2.email = t.contact_email
GROUP BY invoice_id, c1.customer_name, price
ORDER BY invoice_id;

------------------------------------------------------------------------------------------

--Q100 获取最近第二次的活动
SELECT username, activity, startDate, endDate
FROM (
	SELECT username, activity, startDate, endDate
		, COUNT(1) OVER (PARTITION BY username ) AS cnt, rank() OVER (PARTITION BY username ORDER BY startDate DESC) AS px
	FROM useractivity
) u
WHERE cnt = 1
	OR px = 2;
	
------------------------------------------------------------------------------------------

--Q101 使用唯一标识码替换员工ID
SELECT unique_id, name
FROM employees e
	LEFT JOIN employeeuni u ON u.id = e.id;

------------------------------------------------------------------------------------------
	
--Q102 按年度列出销售总额
WITH RECURSIVE num (a, b) AS (
		SELECT product_id, year(period_start) AS nf
		FROM sales
		UNION
		SELECT a, b + 1
		FROM num n
		WHERE b + 1 <= (
			SELECT year(period_end)
			FROM sales s
			WHERE n.a = s.product_id
		)
	)
SELECT a AS product_id, product_name, CAST(b AS char) AS report_year
	, CASE 
		WHEN b = year(period_start)
		AND b = year(period_end) THEN (datediff(period_end, period_start) + 1) * average_daily_sales
		WHEN b = year(period_start) THEN (datediff(concat(b, '-12-31'), period_start) + 1) * average_daily_sales
		WHEN b > year(period_start)
		AND b < year(period_end) THEN (datediff(concat(b, '-12-31'), concat(b, '-01-01')) + 1) * average_daily_sales
		ELSE (datediff(period_end, concat(b, '-01-01')) + 1) * average_daily_sales
	END AS total_amount
FROM num
	LEFT JOIN product p ON p.product_id = num.a
	LEFT JOIN sales s ON s.product_id = num.a
ORDER BY product_id, report_year;

------------------------------------------------------------------------------------------

--Q103 股票的资本损益
SELECT stock_name, SUM(CASE 
		WHEN operation = 'Buy' THEN price * -1
		ELSE price
	END) AS capital_gain_loss
FROM stocks
GROUP BY stock_name;

------------------------------------------------------------------------------------------

--Q104 购买了产品A和产品B却没有购买产品C的顾客
SELECT customer_id, customer_name
FROM (
	SELECT c.customer_id, customer_name
		, ifnull(SUM(CASE 
			WHEN product_name = 'A' THEN 1
			ELSE 0
		END), 0) AS acp
		, ifnull(SUM(CASE 
			WHEN product_name = 'B' THEN 1
			ELSE 0
		END), 0) AS bcp
		, ifnull(SUM(CASE 
			WHEN product_name = 'C' THEN 1
			ELSE 0
		END), 0) AS ccp
	FROM customers c
		LEFT JOIN orders o ON o.customer_id = c.customer_id
	GROUP BY c.customer_id, customer_name
) a
WHERE acp >= 1
	AND bcp >= 1
	AND ccp = 0
ORDER BY customer_id;

------------------------------------------------------------------------------------------

--Q105 排名靠前的旅行者
SELECT name, ifnull(SUM(distance), 0) AS travelled_distance
FROM users u
	LEFT JOIN rides r ON r.user_id = u.id
GROUP BY u.id
ORDER BY travelled_distance DESC, name;

------------------------------------------------------------------------------------------

--Q106 查找成绩处于中游的学生
SELECT student_id, student_name
FROM (
	SELECT s.student_id, student_name
		, CASE 
			WHEN rank() OVER (PARTITION BY exam_id ORDER BY score DESC) = 1
			OR rank() OVER (PARTITION BY exam_id ORDER BY score) = 1 THEN 1
			ELSE 0
		END AS px
	FROM student s
		JOIN exam e ON e.student_id = s.student_id
) a
GROUP BY student_id, student_name
HAVING SUM(px) = 0
ORDER BY student_id;

------------------------------------------------------------------------------------------

--Q107 净现值查询
SELECT q.id, q.year, ifnull(npv, 0) AS npv
FROM queries q
	LEFT JOIN npv n
	ON n.id = q.id
		AND q.year = n.year;

------------------------------------------------------------------------------------------
		
--Q108 制作会话柱状图
SELECT bin, COUNT(fz) total
FROM (
	SELECT '[0-5>' AS bin
	UNION
	SELECT '[5-10>' AS bin
	UNION
	SELECT '[10-15>' AS bin
	UNION
	SELECT '15 or more' AS bin
) a
	LEFT JOIN (
		SELECT CASE 
				WHEN duration < 300 THEN '[0-5>'
				WHEN duration < 600 THEN '[5-10>'
				WHEN duration < 900 THEN '[10-15>'
				ELSE '15 or more'
			END AS fz
		FROM sessions
	) s
	ON s.fz = a.bin
GROUP BY bin;

------------------------------------------------------------------------------------------

--Q109 计算布尔表达式的值
SELECT left_operand, operator, right_operand
	, if(CASE 
		WHEN v1.value = v2.value THEN '='
		WHEN v1.value > v2.value THEN '>'
		ELSE '<'
	END = operator, 'true', 'false') AS 'value'
FROM expressions e
	LEFT JOIN variables v1 ON v1.name = e.left_operand
	LEFT JOIN variables v2 ON v2.name = e.right_operand;
	
------------------------------------------------------------------------------------------

--Q110 苹果和桔子
SELECT sale_date, SUM(CASE 
		WHEN fruit = 'apples' THEN sold_num
		ELSE sold_num * -1
	END) AS diff
FROM sales
GROUP BY sale_date
ORDER BY sale_date;

------------------------------------------------------------------------------------------

--Q111 活跃用户
SELECT iid AS id, name
FROM (
	SELECT DISTINCT id AS iid
	FROM (
		SELECT id
			, CASE 
				WHEN datediff(@dt, @dt := login_date) = -1 THEN @px
				ELSE @px := @px + 1
			END AS cx
		FROM (
			SELECT id, login_date
			FROM logins
			GROUP BY id, login_date
			ORDER BY id, login_date
		) b, (
				SELECT @dt := '2017-01-01', @px := 0
			) a
	) c
	GROUP BY id, cx
	HAVING COUNT(*) >= 5
) d
	LEFT JOIN accounts ac ON ac.id = d.iid
ORDER BY iid;

------------------------------------------------------------------------------------------

--Q112 矩形面积
SELECT p1.id AS p1, p2.id AS p2
	, abs(p1.x_value - p2.x_value) * abs(p1.y_value - p2.y_value) AS area
FROM points p1
	JOIN points p2
	ON p1.id < p2.id
		AND p1.x_value != p2.x_value
		AND p1.y_value != p2.y_value
ORDER BY area DESC, p1, p2;

------------------------------------------------------------------------------------------

--Q113 计算税后工资
SELECT company_id, employee_id, employee_name
	, round(CASE 
		WHEN MAX(salary) OVER (PARTITION BY company_id ) < 1000 THEN salary
		WHEN MAX(salary) OVER (PARTITION BY company_id ) <= 10000 THEN salary * 0.76
		ELSE salary * 0.51
	END, 0) AS salary
FROM salaries;

------------------------------------------------------------------------------------------

--Q114 周内每天的销售情况
SELECT i.item_category AS Category, SUM(CASE 
		WHEN dayname(order_date) = 'Monday' THEN quantity
		ELSE 0
	END) AS 'Monday', SUM(CASE 
		WHEN dayname(order_date) = 'Tuesday' THEN quantity
		ELSE 0
	END) AS 'Tuesday'
	, SUM(CASE 
		WHEN dayname(order_date) = 'Wednesday' THEN quantity
		ELSE 0
	END) AS 'Wednesday', SUM(CASE 
		WHEN dayname(order_date) = 'Thursday' THEN quantity
		ELSE 0
	END) AS 'Thursday'
	, SUM(CASE 
		WHEN dayname(order_date) = 'Friday' THEN quantity
		ELSE 0
	END) AS 'Friday', SUM(CASE 
		WHEN dayname(order_date) = 'Saturday' THEN quantity
		ELSE 0
	END) AS 'Saturday'
	, SUM(CASE 
		WHEN dayname(order_date) = 'Sunday' THEN quantity
		ELSE 0
	END) AS 'Sunday'
FROM items i
	LEFT JOIN orders o ON o.item_id = i.item_id
GROUP BY item_category
ORDER BY Category;

------------------------------------------------------------------------------------------

--Q115 按日期分组销售产品
SELECT sell_date, COUNT(*) num_sold, GROUP_CONCAT(product ORDER BY product SEPARATOR ',') products
FROM (
	SELECT DISTINCT sell_date, product
	FROM activities
) a
GROUP BY sell_date
ORDER BY sell_date;

------------------------------------------------------------------------------------------

--Q116 上月播放的儿童适宜电影
SELECT DISTINCT title AS title
FROM content c
	LEFT JOIN tvprogram t
	ON t.content_id = c.content_id
		AND date_format(program_date, '%Y-%m') = '2020-06'
WHERE kids_content = 'Y'
	AND content_type = 'Movies'
	AND program_date IS NOT NULL;

------------------------------------------------------------------------------------------

--Q117 可以放心投资的国家
WITH temp AS (
		SELECT caller_id AS cid, duration
		FROM calls
		UNION ALL
		SELECT callee_id AS cid, duration
		FROM calls
	)
SELECT DISTINCT name AS country
FROM (
	SELECT c.name
		, CASE 
			WHEN AVG(duration) OVER (PARTITION BY c.name ) > AVG(duration) OVER () THEN 1
			ELSE 0
		END AS px
	FROM temp t
		LEFT JOIN person p ON p.id = t.cid
		LEFT JOIN country c ON c.country_code = LEFT(p.phone_number, 3)
) a
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q118 消费者下单频率
SELECT customer_id, name
FROM (
	SELECT o.customer_id, name, SUM(CASE 
			WHEN date_format(order_date, '%Y-%m') = '2020-06' THEN quantity * price
			ELSE 0
		END) ly
		, SUM(CASE 
			WHEN date_format(order_date, '%Y-%m') = '2020-07' THEN quantity * price
			ELSE 0
		END) qy
	FROM orders o
		LEFT JOIN customers c ON c.customer_id = o.customer_id
		LEFT JOIN product p ON p.product_id = o.product_id
	GROUP BY o.customer_id, name
) a
WHERE ly >= 100
	AND qy >= 100;

------------------------------------------------------------------------------------------

--Q119 查找拥有有效邮箱的用户
SELECT user_id, name, mail
FROM users
WHERE mail REGEXP '^[a-zA-Z][a-zA-Z0-9_./-]*@leetcode\\.com$';

------------------------------------------------------------------------------------------

--Q120 患某种疾病的患者
SELECT patient_id, patient_name, conditions
FROM patients
WHERE conditions REGEXP '^DIAB1'
	OR conditions REGEXP ' DIAB1';
--或者，另一种做法，用 \\s 表示 1个或多个 空格：
SELECT patient_id, patient_name, conditions
FROM patients
WHERE conditions REGEXP '^DIAB1|\\sDIAB1';

------------------------------------------------------------------------------------------

--Q121 最近的三笔订单
SELECT customer_name, customer_id, order_id, order_date
FROM (
	SELECT o.customer_id, name AS customer_name, order_id, order_date, rank() OVER (PARTITION BY o.customer_id ORDER BY order_date DESC) AS px
	FROM orders o
		LEFT JOIN customers c ON c.customer_id = o.customer_id
) a
WHERE px <= 3
ORDER BY customer_name, customer_id, order_date DESC;

------------------------------------------------------------------------------------------

--Q122 产品名称格式修复
SELECT pn product_name, yf sale_date, COUNT(*) total
FROM (
	SELECT lower(trim(product_name)) AS pn
		, date_format(sale_date, '%Y-%m') AS yf
	FROM sales
) s
GROUP BY pn, yf
ORDER BY pn, yf;

------------------------------------------------------------------------------------------

--Q123 每件商品的最新订单
SELECT product_name, product_id, order_id, order_date
FROM (
	SELECT product_name, o.product_id, order_id, order_date, rank() OVER (PARTITION BY o.product_id ORDER BY order_date DESC) AS px
	FROM orders o
		LEFT JOIN products p ON p.product_id = o.product_id
) a
WHERE px = 1
ORDER BY product_name, product_id, order_id;

------------------------------------------------------------------------------------------

--Q124 银行账户概要
SELECT user_id, user_name
	, MIN(credit) + ifnull(SUM(amt), 0) AS credit
	, CASE 
		WHEN MIN(credit) + ifnull(SUM(amt), 0) < 0 THEN 'Yes'
		ELSE 'No'
	END AS credit_limit_breached
FROM users u
	LEFT JOIN (
		SELECT paid_by AS uid, amount * -1 AS amt
		FROM transactions
		UNION ALL
		SELECT paid_to AS uid, amount AS amt
		FROM transactions
	) t
	ON t.uid = u.user_id
GROUP BY user_id, user_name;

------------------------------------------------------------------------------------------

--Q125 按月统计订单数与顾客数
SELECT yf 'month', COUNT(order_id) order_count, COUNT(DISTINCT customer_id) customer_count
FROM (
	SELECT date_format(order_date, '%Y-%m') AS yf, order_id, customer_id
	FROM orders
	WHERE invoice > 20
) a
GROUP BY yf;

------------------------------------------------------------------------------------------

--Q126 仓库经理
SELECT name 'WAREHOUSE_NAME'
	, SUM(units * width * length * height) 'VOLUME'
FROM warehouse w
	LEFT JOIN products p ON p.product_id = w.product_id
GROUP BY name;

------------------------------------------------------------------------------------------

--Q127 进店却未进行过交易的顾客
SELECT customer_id, COUNT(v.visit_id) count_no_trans
FROM visits v
	LEFT JOIN transactions t ON t.visit_id = v.visit_id
WHERE t.visit_id IS NULL
GROUP BY customer_id;

------------------------------------------------------------------------------------------

--Q128 银行账户概要II
SELECT name, SUM(amount) balance
FROM transactions t
	LEFT JOIN users u ON u.account = t.account
GROUP BY t.account
HAVING SUM(amount) > 10000;

------------------------------------------------------------------------------------------

--Q129 每位顾客最经常订购的商品
SELECT customer_id, product_id, product_name
FROM (
	SELECT customer_id, product_id, product_name, rank() OVER (PARTITION BY customer_id ORDER BY cnt DESC) AS px
	FROM (
		SELECT o.customer_id, o.product_id, product_name, COUNT(p.product_id) AS cnt
		FROM orders o
			LEFT JOIN customers c ON c.customer_id = o.customer_id
			LEFT JOIN products p ON o.product_id = p.product_id
		GROUP BY o.customer_id, o.product_id, product_name
	) a
) b
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q130 没有卖出的卖家
SELECT seller_name
FROM seller s
	LEFT JOIN orders o
	ON o.seller_id = s.seller_id
		AND year(sale_date) = 2020
WHERE sale_date IS NULL
ORDER BY seller_name;

------------------------------------------------------------------------------------------

--Q131 找到遗失的ID
WITH RECURSIVE num (n) AS (
		SELECT 1 AS a
		UNION
		SELECT n + 1
		FROM num
		WHERE n + 1 <= (
			SELECT MAX(customer_id)
			FROM customers
		)
	)
SELECT n AS ids
FROM num
	LEFT JOIN customers c ON c.customer_id = num.n
WHERE c.customer_id IS NULL
ORDER BY ids;

------------------------------------------------------------------------------------------

--Q132 三人国家代表队
SELECT a.student_name member_A, b.student_name member_B, c.student_name member_C
FROM schoolA a
	JOIN schoolB b
	ON a.student_id != b.student_id
		AND a.student_name != b.student_name
	JOIN schoolC c
	ON c.student_id != b.student_id
		AND c.student_name != b.student_name
		AND c.student_id != a.student_id
		AND c.student_name != a.student_name;

------------------------------------------------------------------------------------------

--Q133 各赛事的用户注册率
SELECT contest_id
	, round(cnt / unt * 100, 2) percentage
FROM (
	SELECT COUNT(user_id) AS unt
	FROM users
) u
	CROSS JOIN (
		SELECT contest_id, COUNT(user_id) AS cnt
		FROM register
		GROUP BY contest_id
	) r
ORDER BY percentage DESC, contest_id;

------------------------------------------------------------------------------------------

--Q134 Hopper公司查询I
WITH RECURSIVE num (n) AS (
		SELECT 1 AS a
		UNION
		SELECT n + 1
		FROM num
		WHERE n + 1 <= 12
	)
SELECT num.n AS 'month', ifnull(MAX(c.zj) OVER (ORDER BY n), 0) AS active_drivers
	, ifnull(d.cnt, 0) AS 'accepted_rides'
FROM num
	LEFT JOIN (
		SELECT zj, yf
		FROM (
			SELECT SUM(cnt) OVER (ORDER BY nf, yf) AS zj, nf, yf
			FROM (
				SELECT COUNT(1) AS cnt, year(join_date) AS nf
					, month(join_date) AS yf
				FROM drivers
				GROUP BY year(join_date), month(join_date)
			) a
		) b
		WHERE nf = 2020
	) c
	ON c.yf = num.n
	LEFT JOIN (
		SELECT COUNT(ac.ride_id) AS cnt, month(requested_at) AS yf
		FROM acceptedrides ac
			LEFT JOIN rides r ON r.ride_id = ac.ride_id
		WHERE year(requested_at) = 2020
		GROUP BY month(requested_at)
	) d
	ON d.yf = num.n
ORDER BY month;

------------------------------------------------------------------------------------------

--Q135 Hopper Company Queries II
WITH RECURSIVE num (n) AS (
		SELECT 1 AS a
		UNION
		SELECT 1 + n
		FROM num
		WHERE n + 1 <= 12
	)
SELECT n AS 'month'
	, ifnull(round(dcnt / MAX(zj) OVER (ORDER BY n) * 100, 2), 0) AS working_percentage
FROM num
	LEFT JOIN (
		SELECT zj, yf
		FROM (
			SELECT SUM(cnt) OVER (ORDER BY nf, yf) AS zj, nf, yf
			FROM (
				SELECT COUNT(1) AS cnt, year(join_date) AS nf
					, month(join_date) AS yf
				FROM drivers
				GROUP BY year(join_date), month(join_date)
			) a
		) b
		WHERE nf = 2020
	) c
	ON c.yf = num.n
	LEFT JOIN (
		SELECT COUNT(DISTINCT driver_id) AS dcnt, month(requested_at) AS yf
		FROM acceptedrides ac
			LEFT JOIN rides r ON r.ride_id = ac.ride_id
		WHERE year(requested_at) = 2020
		GROUP BY month(requested_at)
	) d
	ON d.yf = num.n;
	
------------------------------------------------------------------------------------------

--Q136 Hopper 公司查询III
with recursive num(n) as(
    select 1 as a 
    union
    select n + 1 from num where n + 1 <= 12
)
select n 'month',avg_jl average_ride_distance,avg_sc average_ride_duration from(
select n,round(avg(zjl)over(order by n range between current row and 2 following),2)avg_jl,round(avg(zsc)over(order by n range between current row and 2 following),2)avg_sc from(
select n,ifnull(jl,0)zjl,ifnull(sc,0)zsc from num left join(
    select month(requested_at)yf,sum(ride_distance)jl,sum(ride_duration)sc from acceptedrides ac left join rides r on r.ride_id = ac.ride_id where year(requested_at) = 2020 group by month(requested_at))a on a.yf = num.n)b)c where n <= 10 order by n;
    
------------------------------------------------------------------------------------------

--Q137 每台机器的进程平均运行时间
SELECT machine_id
	, round(SUM(CASE 
		WHEN activity_type = 'start' THEN timestamp * -1
		ELSE timestamp
	END) / COUNT(DISTINCT process_id), 3) processing_time
FROM activity
GROUP BY machine_id;

------------------------------------------------------------------------------------------

--Q138 修复表中的名字
SELECT user_id
	, concat(upper(substring(name, 1, 1)), lower(RIGHT(name, length(name) - 1))) AS name
FROM users
ORDER BY user_id;

------------------------------------------------------------------------------------------

--Q139 发票中的产品金额
SELECT name, ifnull(SUM(rest), 0) AS rest
	, ifnull(SUM(paid), 0) AS paid
	, ifnull(SUM(canceled), 0) AS canceled
	, ifnull(SUM(refunded), 0) AS refunded
FROM invoice i
	RIGHT JOIN product p ON i.product_id = p.product_id
GROUP BY p.product_id
ORDER BY name;

------------------------------------------------------------------------------------------

--Q140 无效的推文
SELECT tweet_id
FROM tweets
WHERE length(content) > 15;

------------------------------------------------------------------------------------------

--Q141 每天的领导和合伙人
SELECT date_id, make_name, COUNT(DISTINCT lead_id) unique_leads
	, COUNT(DISTINCT partner_id) unique_partners
FROM dailysales
GROUP BY date_id, make_name;

------------------------------------------------------------------------------------------

--Q142 两人之间的通话次数
SELECT person1, person2, COUNT(*) AS call_count
	, SUM(duration) AS total_duration
FROM (
	SELECT from_id AS person1, to_id AS person2, duration
	FROM calls
	WHERE from_id < to_id
	UNION ALL
	SELECT to_id AS person1, from_id AS person2, duration
	FROM calls
	WHERE from_id > to_id
) a
GROUP BY person1, person2;

------------------------------------------------------------------------------------------

--Q143 访问日期之间最大的空档期
SELECT user_id, MAX(rqc) AS biggest_window
FROM (
	SELECT user_id, datediff(CASE 
			WHEN rank() OVER (PARTITION BY user_id ORDER BY visit_date DESC) = 1 THEN '2021-01-01'
			ELSE lead(visit_date) OVER (PARTITION BY user_id ORDER BY visit_date)
		END, visit_date) AS rqc
	FROM uservisits
) u
GROUP BY user_id
ORDER BY user_id;

------------------------------------------------------------------------------------------

--Q144 苹果和橘子的个数
SELECT SUM(b.apple_count + ifnull(c.apple_count, 0)) AS apple_count
	, SUM(b.orange_count + ifnull(c.orange_count, 0)) AS orange_count
FROM boxes b
	LEFT JOIN chests c ON c.chest_id = b.chest_id;
	
------------------------------------------------------------------------------------------

--Q145 求关注者的数量
SELECT user_id, COUNT(*) AS followers_count
FROM followers
GROUP BY user_id
ORDER BY user_id;

------------------------------------------------------------------------------------------

--Q146 每位经理的下属员工数量
SELECT e2.employee_id, e2.name, COUNT(e1.employee_id) AS reports_count
	, round(AVG(e1.age), 0) AS average_age
FROM employees e1
	JOIN employees e2 ON e1.reports_to = e2.employee_id
GROUP BY e2.employee_id, e2.name
ORDER BY e2.employee_id;

------------------------------------------------------------------------------------------

--Q147 查找每个员工花费的总时间
SELECT event_day AS 'day', emp_id, SUM(out_time - in_time) AS total_time
FROM employees
GROUP BY event_day, emp_id;

------------------------------------------------------------------------------------------

--Q148 应该被禁止的Leetflex账户
SELECT DISTINCT l1.account_id
FROM loginfo l1
	JOIN loginfo l2
	ON l1.account_id = l2.account_id
		AND l1.ip_address != l2.ip_address
		AND (l1.login <= l2.login
			AND l1.logout >= l2.login);
			
------------------------------------------------------------------------------------------

--Q149 可回收且低脂的产品
SELECT product_id
FROM products
WHERE low_fats = 'Y'
	AND recyclable = 'Y';

------------------------------------------------------------------------------------------

--Q150 寻找没有被执行的任务对
WITH RECURSIVE num (a, b) AS (
		SELECT task_id, subtasks_count
		FROM tasks
		UNION
		SELECT a, b - 1
		FROM num
		WHERE b - 1 >= 1
	)
SELECT a AS task_id, b AS subtask_id
FROM num
	LEFT JOIN executed e
	ON e.task_id = num.a
		AND e.subtask_id = num.b
WHERE e.task_id IS NULL;

------------------------------------------------------------------------------------------

--Q151 每家商店的产品价格
SELECT product_id, MIN(CASE 
		WHEN store = 'store1' THEN price
	END) AS 'store1', MIN(CASE 
		WHEN store = 'store2' THEN price
	END) AS 'store2'
	, MIN(CASE 
		WHEN store = 'store3' THEN price
	END) AS 'store3'
FROM products
GROUP BY product_id;

------------------------------------------------------------------------------------------

--Q152 大满贯数量
SELECT id AS player_id, player_name, COUNT(*) AS grand_slams_count
FROM (
	SELECT wimbledon AS id
	FROM championships
	UNION ALL
	SELECT fr_open AS id
	FROM championships
	UNION ALL
	SELECT us_open AS id
	FROM championships
	UNION ALL
	SELECT au_open AS id
	FROM championships
) a
	LEFT JOIN players p ON p.player_id = a.id
GROUP BY id;

------------------------------------------------------------------------------------------

--Q153 员工的直属部门
SELECT employee_id, department_id
FROM (
	SELECT employee_id, department_id
		, CASE 
			WHEN COUNT(*) OVER (PARTITION BY employee_id ) > 1
			AND primary_flag = 'Y' THEN 1
			WHEN COUNT(*) OVER (PARTITION BY employee_id ) = 1 THEN 1
			ELSE 0
		END AS px
	FROM employee
) e
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q154 每个产品在不同商店的价格
SELECT product_id, store, price
FROM (
	SELECT product_id, 'store1' AS store, store1 AS price
	FROM products
	UNION ALL
	SELECT product_id, 'store2' AS store, store2 AS price
	FROM products
	UNION ALL
	SELECT product_id, 'store3' AS store, store3 AS price
	FROM products
) p
WHERE price IS NOT NULL;

------------------------------------------------------------------------------------------

--Q155 没有广告的剧集
SELECT session_id
FROM playback p
	LEFT JOIN ads a
	ON a.customer_id = p.customer_id
		AND a.timestamp BETWEEN p.start_time AND p.end_time
WHERE ad_id IS NULL;

------------------------------------------------------------------------------------------

--Q156 寻找面试候选人
WITH temp AS (
		SELECT gold_medal AS uid, contest_id AS play
		FROM contests
		UNION ALL
		SELECT silver_medal AS uid, contest_id AS play
		FROM contests
		UNION ALL
		SELECT bronze_medal AS uid, contest_id AS play
		FROM contests
	)
SELECT name, mail
FROM (
	SELECT uid
	FROM (
		SELECT uid, play
			, CASE 
				WHEN @xc - (@xc := play) = -1 THEN @iid
				ELSE @iid := @iid + 1
			END AS px
		FROM (
			SELECT uid, play
			FROM temp
			ORDER BY uid, play
		) t, (
				SELECT @xc := 200, @iid := 0
			) a
	) b
	GROUP BY uid, px
	HAVING COUNT(*) >= 3
	UNION
	SELECT gold_medal AS uid
	FROM contests
	GROUP BY gold_medal
	HAVING COUNT(*) >= 3
) j
	LEFT JOIN users u ON j.uid = u.user_id
GROUP BY j.uid, u.name, u.mail;

------------------------------------------------------------------------------------------

--Q157 寻找今年具有正收入的客户
SELECT customer_id
FROM customers
WHERE year = 2021
	AND revenue > 0;

------------------------------------------------------------------------------------------

--Q158 每天的最大交易
SELECT transaction_id
FROM (
	SELECT transaction_id, rank() OVER (PARTITION BY date_format(day, '%Y-%m-%d') ORDER BY amount DESC) AS px
	FROM transactions
) t
WHERE px = 1
ORDER BY transaction_id;

------------------------------------------------------------------------------------------

--Q159 联赛信息统计
SELECT team_name, COUNT(tid) AS matches_played, SUM(df) AS points
	, SUM(qs) AS goal_for, SUM(aqs) AS goal_against
	, SUM(qs) - SUM(aqs) AS goal_diff
FROM teams t
	LEFT JOIN (
		SELECT home_team_id AS tid
			, CASE 
				WHEN home_team_goals > away_team_goals THEN 3
				WHEN home_team_goals = away_team_goals THEN 1
				ELSE 0
			END AS df, home_team_goals AS qs, away_team_goals AS aqs
		FROM matches
		UNION ALL
		SELECT away_team_id AS tid
			, CASE 
				WHEN home_team_goals < away_team_goals THEN 3
				WHEN home_team_goals = away_team_goals THEN 1
				ELSE 0
			END AS df, away_team_goals AS qs, home_team_goals AS aqs
		FROM matches
	) m
	ON m.tid = t.team_id
WHERE tid IS NOT NULL
GROUP BY t.team_id
ORDER BY points DESC, goal_diff DESC, team_name;

------------------------------------------------------------------------------------------

--Q160 可疑银行账户
SELECT DISTINCT aid AS account_id
FROM (
	SELECT aid
		, CASE 
			WHEN date_format(lead(yf) OVER (PARTITION BY aid ORDER BY yf), '%Y') = date_format(yf, '%Y')
			AND date_format(lead(yf) OVER (PARTITION BY aid ORDER BY yf), '%m') - 1 = date_format(yf, '%m') THEN 1
			ELSE 0
		END AS px
	FROM (
		SELECT account_id AS aid, SUM(amount) AS amt
			, date_format(day, '%Y-%m-01') AS yf
		FROM transactions
		WHERE type = 'creditor'
		GROUP BY account_id, date_format(day, '%Y-%m-01')
	) a
		LEFT JOIN accounts ac ON ac.account_id = a.aid
	WHERE amt > max_income
) b
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q161 转换日期格式
SELECT date_format(day, '%W, %M %e, %Y') AS 'day'
FROM days;

------------------------------------------------------------------------------------------

--Q162 最大数量高于平均水平的订单
SELECT order_id
FROM (
	SELECT order_id
		, CASE 
			WHEN mj > MAX(pj) OVER () THEN 1
			ELSE 0
		END AS px
	FROM (
		SELECT order_id, AVG(quantity) AS pj, MAX(quantity) AS mj
		FROM ordersdetails
		GROUP BY order_id
	) a
) b
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q163 计算特殊奖金
SELECT employee_id
	, CASE 
		WHEN employee_id % 2 != 0
		AND name NOT REGEXP '^M' THEN salary
		ELSE 0
	END AS bonus
FROM employees
ORDER BY employee_id;

------------------------------------------------------------------------------------------

--Q164 将工资相同的雇员分组
SELECT employee_id, name, salary, dense_rank() OVER (ORDER BY salary) AS team_id
FROM (
	SELECT employee_id, name, salary, COUNT(1) OVER (PARTITION BY salary ) AS cnt
	FROM employees
) e
WHERE cnt > 1
ORDER BY team_id, employee_id;

------------------------------------------------------------------------------------------

--Q165 2020年最后一次登录
SELECT user_id, MAX(time_stamp) last_stamp
FROM logins
WHERE year(time_stamp) = 2020
GROUP BY user_id;

------------------------------------------------------------------------------------------

--Q166 页面推荐II
SELECT f.u2 AS user_id, l1.page_id, COUNT(l1.user_id) AS friends_likes
FROM (
	SELECT user1_id AS u1, user2_id AS u2
	FROM friendship
	UNION
	SELECT user2_id AS u1, user1_id AS u2
	FROM friendship
) f
	LEFT JOIN likes l1 ON l1.user_id = f.u1
	LEFT JOIN likes l2
	ON l2.user_id = f.u2
		AND l2.page_id = l1.page_id
WHERE l2.user_id IS NULL
	AND l1.user_id IS NOT NULL
GROUP BY u2, l1.page_id;

------------------------------------------------------------------------------------------

--Q167 按分类统计薪水
SELECT cat AS category, COUNT(account_id) AS accounts_count
FROM (
	SELECT 'Low Salary' AS cat
	UNION
	SELECT 'Average Salary' AS cat
	UNION
	SELECT 'High Salary' AS cat
) b
	LEFT JOIN (
		SELECT CASE 
				WHEN income < 20000 THEN 'Low Salary'
				WHEN income > 50000 THEN 'High Salary'
				ELSE 'Average Salary'
			END AS dj, account_id
		FROM accounts
	) ac
	ON ac.dj = b.cat
GROUP BY cat;

------------------------------------------------------------------------------------------

--Q168 Leetcodify好友推荐
WITH t AS (
		SELECT DISTINCT user_id, song_id, day
		FROM listens
	), 
	a AS (
		SELECT user1_id AS u1, user2_id AS u2
		FROM friendship
		UNION
		SELECT user2_id AS u1, user1_id AS u2
		FROM friendship
	)
SELECT DISTINCT t1.user_id, t2.user_id AS recommended_id
FROM t t1
	JOIN t t2
	ON t1.user_id != t2.user_id
		AND t1.song_id = t2.song_id
		AND t1.day = t2.day
	LEFT JOIN a
	ON a.u1 = t1.user_id
		AND a.u2 = t2.user_id
WHERE a.u1 IS NULL
GROUP BY t1.user_id, t2.user_id, t1.day
HAVING COUNT(t1.song_id) >= 3;

------------------------------------------------------------------------------------------

--Q169 兴趣相同的朋友
WITH t AS (
		SELECT DISTINCT user_id, song_id, day
		FROM listens
	)
SELECT DISTINCT t1.user_id AS user1_id, t2.user_id AS user2_id
FROM t t1
	JOIN t t2
	ON t1.user_id < t2.user_id
		AND t1.song_id = t2.song_id
		AND t1.day = t2.day
	JOIN friendship f
	ON f.user1_id = t1.user_id
		AND t2.user_id = f.user2_id
WHERE f.user1_id IS NOT NULL
GROUP BY t1.user_id, t2.user_id, t1.day
HAVING COUNT(t1.song_id) >= 3;

------------------------------------------------------------------------------------------

--Q170 确认率
SELECT s.user_id
	, round(SUM(CASE 
		WHEN action = 'confirmed' THEN 1
		ELSE 0
	END) / COUNT(s.user_id), 2) AS confirmation_rate
FROM signups s
	LEFT JOIN confirmations c ON c.user_id = s.user_id
GROUP BY s.user_id;

------------------------------------------------------------------------------------------

--Q171 主动请求确认消息的用户
SELECT DISTINCT user_id
FROM (
	SELECT user_id
		, CASE 
			WHEN timestampdiff(second, time_stamp, lead(time_stamp) OVER (PARTITION BY user_id ORDER BY time_stamp)) <= 24 * 60 * 60 THEN 1
			ELSE 0
		END AS px
	FROM confirmations
) c
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q172 坚定的友谊
WITH temp AS (
		SELECT user1_id AS u1, user2_id AS u2
		FROM friendship
		UNION ALL
		SELECT user2_id AS u1, user1_id AS u2
		FROM friendship
	)
SELECT f1.user1_id, f1.user2_id, COUNT(*) AS common_friend
FROM friendship f1
	LEFT JOIN temp t
	ON t.u1 = f1.user1_id
		AND f1.user2_id != t.u2
	LEFT JOIN temp t2
	ON t2.u1 = f1.user2_id
		AND t.u2 = t2.u2
WHERE t2.u1 IS NOT NULL
GROUP BY f1.user1_id, f1.user2_id
HAVING COUNT(*) >= 3;

------------------------------------------------------------------------------------------

--Q173 查询具有最多共同关注的所有两两结对组
SELECT user1_id, user2_id
FROM (
	SELECT user1_id, user2_id, rank() OVER (ORDER BY cnt DESC) AS px
	FROM (
		SELECT r1.user_id AS user1_id, r2.user_id AS user2_id, COUNT(*) AS cnt
		FROM relations r1
			JOIN relations r2
			ON r1.user_id < r2.user_id
				AND r1.follower_id = r2.follower_id
		GROUP BY r1.user_id, r2.user_id
	) a
) b
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q174 丢失信息的雇员
SELECT a.employee_id
FROM (
	SELECT employee_id
	FROM employees
	UNION
	SELECT employee_id
	FROM salaries
) a
	LEFT JOIN employees e ON e.employee_id = a.employee_id
	LEFT JOIN salaries s ON s.employee_id = a.employee_id
WHERE name IS NULL
	OR salary IS NULL
ORDER BY a.employee_id;

------------------------------------------------------------------------------------------

--Q175 同一天的第一个电话和最后一个电话
SELECT DISTINCT cid AS user_id
FROM (
	SELECT cid, rid
		, CASE 
			WHEN COUNT(1) OVER (PARTITION BY cid, rq ) = 1 THEN 1
			WHEN COUNT(1) OVER (PARTITION BY cid, rq, rid ) = 2 THEN 1
			ELSE 0
		END AS cs
	FROM (
		SELECT cid, rid, rq
			, CASE 
				WHEN rank() OVER (PARTITION BY cid, rq ORDER BY call_time) = 1
				OR rank() OVER (PARTITION BY cid, rq ORDER BY call_time DESC) = 1 THEN 1
				ELSE 0
			END AS px
		FROM (
			SELECT caller_id AS cid, recipient_id AS rid, call_time
				, date_format(call_time, '%Y-%m-%d') AS rq
			FROM calls
			UNION
			SELECT recipient_id AS cid, caller_id AS rid, call_time
				, date_format(call_time, '%Y-%m-%d') AS rq
			FROM calls
		) c
	) a
	WHERE px = 1
) b
WHERE cs = 1;

------------------------------------------------------------------------------------------

--Q176 上级经理已离职的公司员工
SELECT e1.employee_id
FROM employees e1
	LEFT JOIN employees e2 ON e2.employee_id = e1.manager_id
WHERE e2.employee_id IS NULL
	AND e1.salary < 30000
	AND e1.manager_id IS NOT NULL
ORDER BY e1.employee_id;

------------------------------------------------------------------------------------------

--Q177 找出每所学校的最低分数要求
SELECT school_id, ifnull(MIN(score), -1) AS score
FROM schools s
	LEFT JOIN exam e ON e.student_count <= s.capacity
GROUP BY school_id;

------------------------------------------------------------------------------------------

--Q178 统计实验的数量
SELECT a.pf AS platform, b.en AS experiment_name, COUNT(experiment_id) AS num_experiments
FROM (
	SELECT 'Android' AS pf
	UNION
	SELECT 'IOS' AS pf
	UNION
	SELECT 'Web' AS pf
) a
	CROSS JOIN (
		SELECT 'Reading' AS en
		UNION
		SELECT 'Sports' AS en
		UNION
		SELECT 'Programming' AS en
	) b
	LEFT JOIN experiments e
	ON e.platform = a.pf
		AND e.experiment_name = b.en
GROUP BY a.pf, b.en;

------------------------------------------------------------------------------------------

--Q179 职员招聘人数
SELECT dj AS experience, ifnull(ac, 0) AS accepted_candidates
FROM (
	SELECT 'Senior' AS dj
	UNION
	SELECT 'Junior' AS dj
) e
	LEFT JOIN (
		SELECT experience, COUNT(zj) AS ac
		FROM (
			SELECT experience, SUM(xs) OVER (ORDER BY px, salary) AS zj
			FROM (
				SELECT CASE 
						WHEN experience = 'Senior'
						AND SUM(salary) OVER (PARTITION BY experience ORDER BY salary) > 70000 THEN 0
						ELSE salary
					END AS xs, salary, experience
					, CASE 
						WHEN experience = 'Senior' THEN 1
						ELSE 2
					END AS px
				FROM candidates
			) c
			WHERE xs != 0
		) b
		WHERE zj <= 70000
		GROUP BY experience
	) h
	ON e.dj = h.experience;
	
------------------------------------------------------------------------------------------

--Q180 职员招聘人数II
SELECT employee_id
FROM (
	SELECT employee_id, SUM(xs) OVER (ORDER BY px, xs) AS zj
	FROM (
		SELECT employee_id
			, CASE 
				WHEN experience = 'Senior' THEN 1
				ELSE 2
			END AS px
			, CASE 
				WHEN SUM(salary) OVER (PARTITION BY experience ORDER BY salary) > 70000 THEN 0
				ELSE salary
			END AS xs
		FROM candidates
	) a
	WHERE xs != 0
) b
WHERE zj <= 70000;

------------------------------------------------------------------------------------------

--Q181 无流量的账户数
SELECT COUNT(DISTINCT sb.account_id) AS accounts_count
FROM subscriptions sb
	LEFT JOIN streams s
	ON s.account_id = sb.account_id
		AND year(s.stream_date) = 2021
WHERE year(end_date) >= 2021
	AND stream_date IS NULL;
	
------------------------------------------------------------------------------------------

--Q182 低质量的问题
SELECT problem_id
FROM problems
WHERE likes / (likes + dislikes) < 0.6
ORDER BY problem_id;

------------------------------------------------------------------------------------------

--Q183 面试中被录取的候选人
SELECT candidate_id
FROM candidates c
	LEFT JOIN rounds r ON r.interview_id = c.interview_id
GROUP BY c.candidate_id
HAVING MIN(years_of_exp) >= 2
AND SUM(score) > 15;

------------------------------------------------------------------------------------------

--Q184 The Category of Each Member in the Store
SELECT m.member_id, name
	, CASE 
		WHEN COUNT(v.visit_id) = 0 THEN 'Bronze'
		WHEN COUNT(p.visit_id) / COUNT(v.visit_id) < 0.5 THEN 'Silver'
		WHEN COUNT(p.visit_id) / COUNT(v.visit_id) < 0.8 THEN 'Gold'
		ELSE 'Diamond'
	END AS category
FROM members m
	LEFT JOIN visits v ON v.member_id = m.member_id
	LEFT JOIN purchases p ON p.visit_id = v.visit_id
GROUP BY m.member_id, name;

------------------------------------------------------------------------------------------

--Q185 账户余额
SELECT account_id,
        day,
        sum(if(type = 'Deposit',amount,amount*(-1)))over(partition by account_id
ORDER BY  day) 'balance'
FROM transactions
ORDER BY  account_id,day;

------------------------------------------------------------------------------------------

--Q186 赢得比赛的大学
SELECT CASE 
		WHEN nnt > cnt THEN 'New York University'
		WHEN nnt < cnt THEN 'California University'
		ELSE 'No Winner'
	END AS winner
FROM (
	SELECT COUNT(*) AS nnt
	FROM newyork
	WHERE score >= 90
) a
	CROSS JOIN (
		SELECT COUNT(*) AS cnt
		FROM california
		WHERE score >= 90
	) b;

------------------------------------------------------------------------------------------

--Q187 富有客户的数量
SELECT COUNT(DISTINCT customer_id) AS rich_count
FROM store
WHERE amount > 500;

------------------------------------------------------------------------------------------

--Q188 为订单类型为0的客户删除类型为1的订单
SELECT order_id, customer_id, px AS order_type
FROM (
	SELECT order_id, customer_id
		, CASE 
			WHEN count(1) OVER (PARTITION BY customer_id ) = sum(if(order_type = 1, 1, 0)) OVER (PARTITION BY customer_id ) THEN 1
			WHEN order_type = 0 THEN 0
			ELSE 2
		END AS px
	FROM orders
) o
WHERE px != 2;

------------------------------------------------------------------------------------------

--Q189 The Airport With the Most Traffic

SELECT did AS airport_id
FROM (
	SELECT did, rank() OVER (ORDER BY cnt DESC) AS px
	FROM (
		SELECT did, SUM(fl) AS cnt
		FROM (
			SELECT departure_airport AS did, flights_count AS fl
			FROM flights
			UNION ALL
			SELECT arrival_airport AS did, flights_count AS fl
			FROM flights
		) f
		GROUP BY did
	) b
) c
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q190 Build the Equation
SELECT concat(GROUP_CONCAT(concat(CASE 
		WHEN factor > 0 THEN concat('+', factor)
		ELSE factor
	END, CASE 
		WHEN power = 1 THEN 'X'
		WHEN power > 1 THEN concat('X^', power)
		ELSE ''
	END) ORDER BY power DESC SEPARATOR ''), '=0') AS equation
FROM terms;

------------------------------------------------------------------------------------------

--Q191 The Number of Passengers in Each Bus I
SELECT d.bus_id, ifnull(cnt, 0) AS passengers_cnt
FROM buses d
	LEFT JOIN (
		SELECT bid, COUNT(px) AS cnt
		FROM (
			SELECT bus_id AS bid, rank() OVER (PARTITION BY pid ORDER BY bt) AS px
			FROM (
				SELECT bus_id, b.arrival_time AS bt, passenger_id AS pid, p.arrival_time AS pt
				FROM buses b
					LEFT JOIN passengers p ON p.arrival_time <= b.arrival_time
				WHERE p.passenger_id IS NOT NULL
			) a
		) c
		WHERE px = 1
		GROUP BY bid
	) e
	ON e.bid = d.bus_id
ORDER BY bus_id;

------------------------------------------------------------------------------------------

--Q192 The Number of Passengers in Each Bus II
SELECT bus_id
	, if(rs > 0, cnt - rs, cnt) AS passengers_cnt
FROM buses d
	LEFT JOIN (
		SELECT lx, id
			, CASE 
				WHEN @gs > 0 THEN @gs := cnt
				ELSE @gs := @gs + cnt
			END AS rs, cnt
		FROM (
			SELECT lx, id, at, cnt
			FROM (
				SELECT 'b' AS lx, bus_id AS id, arrival_time AS at, capacity AS cnt
				FROM buses
				UNION ALL
				SELECT 'p' AS lx, passenger_id AS id, arrival_time AS at, -1 AS cnt
				FROM passengers
			) a
			ORDER BY at, lx DESC
		) b, (
				SELECT @gs := 0
			) c
	) e
	ON e.id = d.bus_id
		AND lx = 'b'
ORDER BY bus_id;

------------------------------------------------------------------------------------------

--Q193 Order Two Columns Independently
SELECT d1.first_col, d2.second_col
FROM (
	SELECT first_col, row_number() OVER (ORDER BY first_col) AS sx
	FROM data
) d1
	JOIN (
		SELECT second_col, row_number() OVER (ORDER BY second_col DESC) AS jx
		FROM data
	) d2
	ON d1.sx = d2.jx
ORDER BY d1.sx;

------------------------------------------------------------------------------------------

--Q194 最多连胜的次数
WITH temp AS (
		SELECT player_id, result
			, CASE 
				WHEN result = 'Win' THEN @sx
				ELSE @sx := @sx + 1
			END AS px
		FROM (
			SELECT player_id, match_day, result
			FROM matches
			ORDER BY player_id, match_day
		) m, (
				SELECT @sx := 0
			) a
	)
SELECT DISTINCT m.player_id, ifnull(cnt, 0) AS longest_streak
FROM matches m
	LEFT JOIN (
		SELECT player_id, cnt
		FROM (
			SELECT player_id, cnt, rank() OVER (PARTITION BY player_id ORDER BY cnt DESC) AS cx
			FROM (
				SELECT player_id
					, CASE 
						WHEN result = 'Win' THEN 1
						ELSE 0
					END AS ch, px, COUNT(1) AS cnt
				FROM temp
				GROUP BY player_id, result, px
			) a
			WHERE ch = 1
		) b
		WHERE cx = 1
	) c
	ON c.player_id = m.player_id;
	
------------------------------------------------------------------------------------------

--Q195 The Change in Global Rankings
SELECT team_id, name, CAST(row_number() OVER (ORDER BY qj DESC, name) AS signed) - CAST(row_number() OVER (ORDER BY hj DESC, name) AS signed) AS rank_diff
FROM (
	SELECT t.team_id, name, points AS qj
		, points + ifnull(points_change, 0) AS hj
	FROM teampoints t
		LEFT JOIN pointschange p ON p.team_id = t.team_id
) a;

------------------------------------------------------------------------------------------

--Q196 Finding the Topic of Each Post
SELECT post_id, ifnull(GROUP_CONCAT(tt ORDER BY tt), 'Ambiguous!') AS topic
FROM (
	SELECT DISTINCT post_id, topic_id AS tt
	FROM posts p
		LEFT JOIN keywords k ON instr(concat(' ', content, ' '), concat(' ', word, ' ')) > 0
) a
GROUP BY post_id;

------------------------------------------------------------------------------------------

--Q197 The Number of Users Tha Are Eligible for Discount
CREATE FUNCTION getUserIDs (
	startDate DATE, 
	endDate DATE, 
	minAmount INT
)
RETURNS INT
BEGIN
	RETURN 
		SELECT COUNT(DISTINCT user_id) AS user_cnt
		FROM purchases
		WHERE time_stamp BETWEEN startDate AND endDate
			AND amount >= minAmount;
END

------------------------------------------------------------------------------------------

--Q198 Users With Two Purchases Within Seven Days
SELECT DISTINCT user_id
FROM (
	SELECT user_id
		, CASE 
			WHEN datediff(lead(purchase_date) OVER (PARTITION BY user_id ORDER BY purchase_date), purchase_date) <= 7 THEN 1
			ELSE 0
		END AS px
	FROM purchases
) p
WHERE px = 1;

------------------------------------------------------------------------------------------

--Q199 The Users That Are Eligible for Discount
CREATE PROCEDURE getUserIDs (
	startDate DATE, 
	endDate DATE, 
	minAmount INT
)
BEGIN

	SELECT DISTINCT user_id
	FROM purchases
	WHERE time_stamp BETWEEN startDate AND endDate
		AND amount >= minAmount
	ORDER BY user_id;
END

------------------------------------------------------------------------------------------

--Q200 Number of Times a Driver Was a Passenger
SELECT r1.did AS driver_id, COUNT(passenger_id) AS cnt
FROM (
	SELECT DISTINCT driver_id AS did
	FROM rides
) r1
	LEFT JOIN rides r2 ON r1.did = r2.passenger_id
GROUP BY did;

------------------------------------------------------------------------------------------

--Q201 Dynamic Pivoting of a Table--涉及构建过程(较难)
CREATE PROCEDURE PivotProducts ()
BEGIN
	SET group_concat_max_len = 100000;
	SET @ss = NULL;
	SELECT GROUP_CONCAT(DISTINCT concat('max(if(store=''', store, ''',price,null))', store) ORDER BY store)
	INTO @ss
	FROM products;
	SET @ss = concat('select product_id, ', @ss, ' from products group by product_id');
	PREPARE si FROM @ss;
	EXECUTE si;
	DEALLOCATE PREPARE si;
END

------------------------------------------------------------------------------------------

--Q202 Dynamic Unpivoting of a Table--仍涉及构建过程(较难)
CREATE PROCEDURE UnpivotProducts()
BEGIN
    # Write your MySQL query statement below.
    DECLARE store_name varchar(100) DEFAULT '';
    DECLARE done INT;
    DECLARE product_cursor CURSOR FOR
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'Products' AND column_name <> 'product_id';
    DECLARE CONTINUE HANDLER FOR  SQLSTATE '02000' SET done = 1;
    SET @ss = '';
    OPEN product_cursor;
    REPEAT 
        FETCH product_cursor INTO store_name;
        SET @ss = concat(@ss, 'select product_id, ''', store_name, ''' store,', store_name, ' price from Products where ', store_name, ' is not null union ');
    UNTIL done
    END REPEAT;
    CLOSE product_cursor;
    SET @ss = substring(@ss, 1, length(@ss) - 7);
    PREPARE si FROM @ss;
    EXECUTE si;
    DEALLOCATE PREPARE si;
END

------------------------------------------------------------------------------------------

--Q203 Products With Three or More Orders in Two Consecutive Years
SELECT DISTINCT product_id
FROM (
	SELECT product_id
		, CASE 
			WHEN lead(nf) OVER (PARTITION BY product_id ORDER BY nf) - nf = 1 THEN 1
			ELSE 0
		END AS px
	FROM (
		SELECT product_id, year(purchase_date) AS nf
		FROM orders
		GROUP BY product_id, year(purchase_date)
		HAVING COUNT(1) >= 3
	) a
) b
WHERE px = 1;

------------------------------------------------------------------------------------------


