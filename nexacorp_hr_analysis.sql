/*
====================================================================
 PROJECT: NexaCorp HR Analytics
 DATABASE: corporate (nexacorp_hr)
 TABLES: departments, employees, salaries, performance_reviews,
         projects, employee_projects
 AUTHOR: [Your Name]
 DESCRIPTION:
   20 real-world, corporate-level HR analytics questions covering
   headcount, management hierarchy (self-join), compensation,
   performance, tenure, workload, and diversity — the kind of
   questions a People Analytics / HR Data Analyst answers regularly.
====================================================================
*/


-- ====================================================================
-- SECTION 1: HEADCOUNT & ORGANIZATION STRUCTURE
-- ====================================================================

-- Q1: How many employees work in each department? Which is the largest?
SELECT d.department_name, COUNT(e.employee_id) AS total_employees
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY total_employees DESC;


-- Q2: Who are the top 3 managers by team size (most direct reports)?
-- Uses a self-join: the employees table is joined to itself to link
-- each employee to their manager (who is also a row in employees).
SELECT m.employee_id AS manager_id,
       m.first_name AS manager_first_name,
       m.last_name AS manager_last_name,
       COUNT(e.employee_id) AS total_reports
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
GROUP BY m.employee_id, m.first_name, m.last_name
ORDER BY total_reports DESC
LIMIT 3;


-- Q3: Who are the senior leaders with no manager (top of the org chart)?
SELECT employee_id, first_name, last_name, department_id, job_title
FROM employees
WHERE manager_id IS NULL;


-- Q4: What is the average tenure (in years) of employees in each department?
SELECT d.department_name,
       ROUND(AVG(DATEDIFF(CURDATE(), e.hire_date) / 365.0), 1) AS avg_tenure_years
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY avg_tenure_years DESC;


-- Q5: How many employees were hired each year? (hiring trend)
SELECT YEAR(hire_date) AS hire_year, COUNT(*) AS employees_hired
FROM employees
GROUP BY YEAR(hire_date)
ORDER BY hire_year;


-- Q6: What is the running total (cumulative) headcount growth by year?
WITH yearly_hires AS (
    SELECT YEAR(hire_date) AS hire_year, COUNT(*) AS employees_hired
    FROM employees
    GROUP BY YEAR(hire_date)
)
SELECT hire_year, employees_hired,
       SUM(employees_hired) OVER (ORDER BY hire_year) AS cumulative_headcount
FROM yearly_hires
ORDER BY hire_year;


-- Q7: What is the gender diversity ratio (% female) in each department?
SELECT d.department_name,
       COUNT(CASE WHEN e.gender = 'Female' THEN 1 END) AS female_count,
       COUNT(*) AS total_count,
       ROUND(COUNT(CASE WHEN e.gender = 'Female' THEN 1 END) * 100.0 / COUNT(*), 1) AS female_pct
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY female_pct DESC;


-- ====================================================================
-- SECTION 2: COMPENSATION
-- ====================================================================

-- Q8: What is each employee's current (most recent) salary?
-- Pattern: rank each employee's salary records by date, keep only rank 1.
WITH latest_salary AS (
    SELECT employee_id, salary_amount, effective_date,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY effective_date DESC) AS rn
    FROM salaries
)
SELECT employee_id, salary_amount, effective_date
FROM latest_salary
WHERE rn = 1;


-- Q9: What is the average current salary in each department?
WITH latest_salary AS (
    SELECT employee_id, salary_amount,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY effective_date DESC) AS rn
    FROM salaries
)
SELECT d.department_name, ROUND(AVG(ls.salary_amount), 0) AS avg_current_salary
FROM latest_salary ls
JOIN employees e ON ls.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
WHERE ls.rn = 1
GROUP BY d.department_name
ORDER BY avg_current_salary DESC;


-- Q10: What is the salary growth % for each employee, comparing their
--      first recorded salary to their latest one?
WITH salary_bounds AS (
    SELECT employee_id,
           FIRST_VALUE(salary_amount) OVER (PARTITION BY employee_id ORDER BY effective_date ASC) AS first_salary,
           FIRST_VALUE(salary_amount) OVER (PARTITION BY employee_id ORDER BY effective_date DESC) AS latest_salary
    FROM salaries
)
SELECT DISTINCT employee_id, first_salary, latest_salary,
       ROUND((latest_salary - first_salary) * 100.0 / first_salary, 1) AS growth_percent
FROM salary_bounds
ORDER BY growth_percent DESC;


-- Q11: Top 5 highest currently-paid employees company-wide (with name and department).
WITH latest_salary AS (
    SELECT employee_id, salary_amount,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY effective_date DESC) AS rn
    FROM salaries
)
SELECT e.first_name, e.last_name, d.department_name, ls.salary_amount
FROM latest_salary ls
JOIN employees e ON ls.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
WHERE ls.rn = 1
ORDER BY ls.salary_amount DESC
LIMIT 5;


-- Q12: Is there a gender pay gap? Compare average current salary by
--      gender within each department.
WITH latest_salary AS (
    SELECT employee_id, salary_amount,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY effective_date DESC) AS rn
    FROM salaries
)
SELECT d.department_name, e.gender, ROUND(AVG(ls.salary_amount), 0) AS avg_salary
FROM latest_salary ls
JOIN employees e ON ls.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
WHERE ls.rn = 1
GROUP BY d.department_name, e.gender
ORDER BY d.department_name, e.gender;


-- ====================================================================
-- SECTION 3: PERFORMANCE
-- ====================================================================

-- Q13: Which employees are consistently high performers
--      (average rating across all their reviews > 4)?
SELECT e.first_name, e.last_name, ROUND(AVG(pr.rating), 2) AS avg_rating
FROM performance_reviews pr
JOIN employees e ON pr.employee_id = e.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING AVG(pr.rating) > 4
ORDER BY avg_rating DESC;


-- Q14: What is the promotion rate (%) in each department
--      (promoted reviews / total reviews)?
SELECT d.department_name,
       SUM(pr.promoted) AS total_promotions,
       COUNT(*) AS total_reviews,
       ROUND(SUM(pr.promoted) * 100.0 / COUNT(*), 1) AS promotion_rate_pct
FROM performance_reviews pr
JOIN employees e ON pr.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY promotion_rate_pct DESC;


-- Q15: What is the average performance rating trend across the company,
--      period over period?
SELECT review_period, ROUND(AVG(rating), 2) AS avg_rating
FROM performance_reviews
GROUP BY review_period
ORDER BY review_period;


-- Q16: Which employees have had 3 or more reviews but have NEVER been promoted?
--      (Retention risk — strong tenure, no recognition)
SELECT e.first_name, e.last_name, COUNT(pr.review_id) AS total_reviews
FROM performance_reviews pr
JOIN employees e ON pr.employee_id = e.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING COUNT(pr.review_id) >= 3 AND SUM(pr.promoted) = 0
ORDER BY total_reviews DESC;


-- Q17: For each employee with 2+ reviews, did their most recent rating
--      improve or decline compared to their previous review?
-- Uses LAG() to compare each review to the one before it, per employee.
SELECT e.first_name, e.last_name, pr.review_period, pr.rating,
       LAG(pr.rating) OVER (PARTITION BY pr.employee_id ORDER BY pr.review_period) AS previous_rating,
       pr.rating - LAG(pr.rating) OVER (PARTITION BY pr.employee_id ORDER BY pr.review_period) AS rating_change
FROM performance_reviews pr
JOIN employees e ON pr.employee_id = e.employee_id
ORDER BY e.employee_id, pr.review_period;


-- ====================================================================
-- SECTION 4: PROJECTS & WORKLOAD
-- ====================================================================

-- Q18: Which department has the most delayed or cancelled projects?
SELECT d.department_name, p.status, COUNT(*) AS project_count
FROM projects p
JOIN departments d ON p.department_id = d.department_id
WHERE p.status IN ('Delayed', 'Cancelled')
GROUP BY d.department_name, p.status
ORDER BY project_count DESC;


-- Q19: Which employees are allocated more than 300 hours across their
--      projects (potential overload / burnout risk)?
SELECT e.first_name, e.last_name, SUM(ep.hours_allocated) AS total_hours
FROM employee_projects ep
JOIN employees e ON ep.employee_id = e.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING SUM(ep.hours_allocated) > 300
ORDER BY total_hours DESC;


-- Q20: How does each department's project budget compare to its
--      allocated department budget (are departments overspending on projects)?
SELECT d.department_name, d.budget AS department_budget,
       SUM(p.budget) AS total_project_budget,
       ROUND(SUM(p.budget) * 100.0 / d.budget, 1) AS project_spend_pct_of_budget
FROM projects p
JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department_name, d.budget
ORDER BY project_spend_pct_of_budget DESC;
