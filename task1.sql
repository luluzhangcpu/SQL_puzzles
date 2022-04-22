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

------------------------------------------------------------------------------------------

--Q19 至少有5名直接下属的经理
SELECT e2.name
FROM employee e1
	JOIN employee e2 ON e1.managerid = e2.id
GROUP BY e1.managerid
HAVING COUNT(e1.id) >= 5;

------------------------------------------------------------------------------------------

--Q20 给定数字的频率查询中位数

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

------------------------------------------------------------------------------------------

--Q42 学生地理信息报告

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

------------------------------------------------------------------------------------------

--Q61 每位学生的最高成绩

------------------------------------------------------------------------------------------

--Q62 报告的记录
SELECT extra report_reason, COUNT(DISTINCT post_id) report_count
FROM actions
WHERE action = 'report'
	AND action_date = '2019-07-04'
GROUP BY extra;

------------------------------------------------------------------------------------------

--Q63 查询活跃业务

------------------------------------------------------------------------------------------

--Q64 用户购买平台

------------------------------------------------------------------------------------------

--Q65 报告的记录II

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

------------------------------------------------------------------------------------------

--Q70 市场分析I

------------------------------------------------------------------------------------------

--Q71 市场分析II

------------------------------------------------------------------------------------------

--Q72 指定日期的产品价格

------------------------------------------------------------------------------------------

--Q73 即时食物配送I
SELECT round(SUM(CASE 
		WHEN order_date = customer_pref_delivery_date THEN 1
		ELSE 0
	END) / COUNT(*) * 100, 2) immediate_percentage
FROM delivery;

------------------------------------------------------------------------------------------

--Q74 即时食物配送II

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

------------------------------------------------------------------------------------------

--Q77 锦标赛优胜者

------------------------------------------------------------------------------------------

--Q78 最后一个能进入电梯的人

------------------------------------------------------------------------------------------

--Q79 每月交易II

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

------------------------------------------------------------------------------------------

--Q82 报告系统状态的连续日期

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

------------------------------------------------------------------------------------------

--Q86 向公司CEO汇报工作的所有人

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

------------------------------------------------------------------------------------------

--Q92 餐馆营业额变化增长

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

------------------------------------------------------------------------------------------

--Q96 电影评分

------------------------------------------------------------------------------------------

--Q97 院系无效的学生
SELECT s.id, s.name
FROM students s
	LEFT JOIN departments d ON d.id = s.department_id
WHERE d.id IS NULL;

------------------------------------------------------------------------------------------

--Q98 活动参与者

------------------------------------------------------------------------------------------

--Q99 顾客的可信联系人数量

------------------------------------------------------------------------------------------

--Q100 获取最近第二次的活动

------------------------------------------------------------------------------------------

--Q101 使用唯一标识码替换员工ID
SELECT unique_id, name
FROM employees e
	LEFT JOIN employeeuni u ON u.id = e.id;

------------------------------------------------------------------------------------------
	
--Q102 按年度列出销售总额

------------------------------------------------------------------------------------------

--Q103 股票的资本损益

------------------------------------------------------------------------------------------

--Q104 购买了产品A和产品B却没有购买产品C的顾客

------------------------------------------------------------------------------------------

--Q105 排名靠前的旅行者
SELECT name, ifnull(SUM(distance), 0) AS travelled_distance
FROM users u
	LEFT JOIN rides r ON r.user_id = u.id
GROUP BY u.id
ORDER BY travelled_distance DESC, name;

------------------------------------------------------------------------------------------

--Q106 查找成绩处于中游的学生

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

------------------------------------------------------------------------------------------

--Q110 苹果和桔子

------------------------------------------------------------------------------------------

--Q111 活跃用户

------------------------------------------------------------------------------------------

--Q112 矩形面积

------------------------------------------------------------------------------------------

--Q113 计算税后工资

------------------------------------------------------------------------------------------

--Q114 周内每天的销售情况

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

------------------------------------------------------------------------------------------

--Q124 银行账户概要

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

------------------------------------------------------------------------------------------

--Q135 Hopper Company Queries II

------------------------------------------------------------------------------------------

--Q136 Hopper 公司查询III

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

------------------------------------------------------------------------------------------

--Q143 访问日期之间最大的空档期

------------------------------------------------------------------------------------------

--Q144 苹果和橘子的个数

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

------------------------------------------------------------------------------------------

--Q149 可回收且低脂的产品
SELECT product_id
FROM products
WHERE low_fats = 'Y'
	AND recyclable = 'Y';

------------------------------------------------------------------------------------------

--Q150 寻找没有被执行的任务对

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

------------------------------------------------------------------------------------------

--Q157 寻找今年具有正收入的客户
SELECT customer_id
FROM customers
WHERE year = 2021
	AND revenue > 0;

------------------------------------------------------------------------------------------

--Q158 每天的最大交易

------------------------------------------------------------------------------------------

--Q159 联赛信息统计

------------------------------------------------------------------------------------------

--Q160 可疑银行账户

------------------------------------------------------------------------------------------

--Q161 转换日期格式
SELECT date_format(day, '%W, %M %e, %Y') AS 'day'
FROM days;

------------------------------------------------------------------------------------------

--Q162 最大数量高于平均水平的订单

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

------------------------------------------------------------------------------------------

--Q165 2020年最后一次登录
SELECT user_id, MAX(time_stamp) last_stamp
FROM logins
WHERE year(time_stamp) = 2020
GROUP BY user_id;

------------------------------------------------------------------------------------------

--Q166 页面推荐II

------------------------------------------------------------------------------------------

--Q167 按分类统计薪水

------------------------------------------------------------------------------------------

--Q168 Leetcodify好友推荐

------------------------------------------------------------------------------------------

--Q169 兴趣相同的朋友

------------------------------------------------------------------------------------------

--Q170 确认率

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

------------------------------------------------------------------------------------------

--Q173 查询具有最多共同关注的所有两两结对组

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

------------------------------------------------------------------------------------------

--Q180 职员招聘人数II

------------------------------------------------------------------------------------------

--Q181 无流量的账户数

------------------------------------------------------------------------------------------

--Q182 低质量的问题
SELECT problem_id
FROM problems
WHERE likes / (likes + dislikes) < 0.6
ORDER BY problem_id;

------------------------------------------------------------------------------------------

--Q183 面试中被录取的候选人

------------------------------------------------------------------------------------------

--Q184 The Category of Each Member in the Store

------------------------------------------------------------------------------------------

--Q185 账户余额

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

------------------------------------------------------------------------------------------

--Q189 The Airport With the Most Traffic

------------------------------------------------------------------------------------------

--Q190 Build the Equation

------------------------------------------------------------------------------------------

--Q191 The Number of Passengers in Each Bus I

------------------------------------------------------------------------------------------

--Q192 The Number of Passengers in Each Bus II

------------------------------------------------------------------------------------------

--Q193 Order Two Columns Independently

------------------------------------------------------------------------------------------

--Q194 最多连胜的次数

------------------------------------------------------------------------------------------

--Q195 The Change in Global Rankings

------------------------------------------------------------------------------------------

--Q196 Finding the Topic of Each Post

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

------------------------------------------------------------------------------------------


