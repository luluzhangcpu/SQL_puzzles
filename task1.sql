
/*
task1--组合两个表
如果 personId 的地址不在 Address 表中，则报告为 null；
以 任意顺序 返回结果表；
将a表和b表 对应键连接起来，并取相对应的字段；
*/
SELECT p.firstname, p.lastname, a.city, a.state
FROM person p
	LEFT JOIN address a ON a.personid = p.personid;

/*
task2--第二高的薪水
编写一个 SQL 查询，获取并返回 Employee 表中第二高的薪水
如果不存在第二高的薪水，查询应该返回 null;
*/
SELECT MIN(salary) AS SecondHighestSalary
FROM (
	SELECT salary, dense_rank() OVER (ORDER BY salary DESC) AS px
	FROM employee
) e
WHERE px = 2;

/*
task3--第N高的薪水
编写一个SQL查询来报告 Employee 表中第 n 高的工资;
如果没有第 n 个最高工资，查询应该报告为 null;
*/
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
  
/*
task4--分数排名
编写 SQL 查询对分数进行降序排列；
*/







