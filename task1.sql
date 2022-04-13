
/*
task1--组合两个表
如果 personId 的地址不在 Address 表中，则报告为空  null；
以 任意顺序 返回结果表；
将a表和b表 对应键连接起来，并取相对应的字段；
*/
SELECT p.firstname, p.lastname, a.city, a.state
FROM person p
	LEFT JOIN address a ON a.personid = p.personid;

/*
task2--第二高的薪水
# 编写一个 SQL 查询，获取并返回 Employee 表中第二高的薪水 。
# 如果不存在第二高的薪水，查询应该返回 null
*/
SELECT (
		SELECT DISTINCT salary
		FROM (
			SELECT dense_rank() OVER (ORDER BY salary DESC) AS px, salary
			FROM employee
		) e
		WHERE px = 2
	) AS SecondHighestSalary;
  
  
