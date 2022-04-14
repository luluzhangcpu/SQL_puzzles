
--task1--组合两个表,将对应键连接起来，并取相对应的字段；
SELECT p.firstname, p.lastname, a.city, a.state
FROM person p
	LEFT JOIN address a ON a.personid = p.personid;


--task2--第二高的薪水，获取并返回 Employee 表中第二高的薪水，若不存在，返回 null;
SELECT MIN(salary) AS SecondHighestSalary
FROM (
	SELECT salary, dense_rank() OVER (ORDER BY salary DESC) AS px
	FROM employee
) e
WHERE px = 2;


--task3--第N高的薪水，获取 Employee 表第 n 高的工资，若不存在，返回null;
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
  
--task4--分数排名，对分数进行降序排列；







