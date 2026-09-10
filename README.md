# 🏢 NexaCorp HR Analytics — SQL Project

## 📌 Overview
NexaCorp is a fictitious mid-size company (220 employees, 8 departments) used to simulate a real-world **People Analytics** engagement. This project uses **MySQL** to analyze headcount, management structure, compensation, performance, and project workload — the kind of analysis an HR Data Analyst delivers to leadership on a recurring basis.

The project deliberately uses a **6-table relational schema** (including a self-referencing manager hierarchy and salary history) to practice and demonstrate advanced SQL: multi-table JOINs, self-joins, CTEs, window functions (`ROW_NUMBER`, `LAG`, `FIRST_VALUE`), and aggregate analysis with `HAVING`.

---

## 🗂️ Dataset & Schema

| Table | Rows | Description |
|---|---|---|
| `departments` | 8 | Department name, location, annual budget |
| `employees` | 220 | Employee details, including a self-referencing `manager_id` |
| `salaries` | 370 | Salary history — each employee has 1–3 records over time (raises) |
| `performance_reviews` | 510 | Half-yearly reviews (rating 1–5, promotion flag) |
| `projects` | 33 | Department-owned projects, budget, and status |
| `employee_projects` | 186 | Many-to-many mapping of employees to project assignments |

**Relationships:**
```
departments ─┬─< employees ─┬─< salaries
             │               ├─< performance_reviews
             │               └─< employee_projects >─ projects
             └─< projects
employees.manager_id → employees.employee_id  (self-referencing hierarchy)
```

---

## 🛠️ Tools Used
- **MySQL Workbench** — schema design, data import (`LOAD DATA INFILE`), query execution
- **SQL** — JOINs (including self-joins), CTEs, window functions, subqueries, aggregate analysis

---

## ❓ Business Questions Answered
20 corporate-level questions across 4 categories, fully documented with comments in [`nexacorp_hr_analysis.sql`](./nexacorp_hr_analysis.sql):

1. **Headcount & Organization Structure** — department sizes, management hierarchy (self-join), tenure, hiring trends, gender diversity
2. **Compensation** — current salary per employee (latest-record pattern), department pay levels, salary growth, top earners, gender pay gap
3. **Performance** — high performers, promotion rates, rating trends, retention-risk employees, rating trajectory (`LAG`)
4. **Projects & Workload** — delayed/cancelled projects, workload/burnout risk, project spend vs. department budget

---

## 📊 Key Findings

### Organization
- **Human Resources** is the largest department (32 employees), followed by Product (30) and Sales (29); **Engineering** is the smallest (24)
- The top 3 people-managers each oversee **28–31 direct reports** — a notably wide span of control worth reviewing for management overhead
- Average tenure ranges from **4.4 years (Marketing)** to **5.8 years (Engineering & Finance)** — Marketing has the highest turnover risk based on tenure alone
- Gender diversity varies sharply by department: **Operations is 70% female**, while **Customer Support is only 28% female** — a clear DEI focus area

### Compensation
- **Sales** has by far the highest average current salary (₹21.3 lakh), nearly **double** the company-wide average (₹14.2 lakh) — largely driven by commission-heavy senior roles
- **117 of 220 employees (53%)** have received at least one raise since joining, with an average increase of **17.6%**
- All of the **top 5 highest-paid employees** are in Sales — a concentration risk if the department underperforms
- A modest **gender pay gap exists company-wide**: male employees average ₹14.5 lakh vs. ₹13.95 lakh for female employees (~4% gap)

### Performance
- Only **40 of 217 reviewed employees (18%)** are consistent high performers (average rating > 4)
- **Human Resources has the highest promotion rate (12.9%)**, while **Engineering has had zero promotions** across the review history captured — a potential retention red flag for a technical team
- Company-wide average rating has **drifted down slightly**, from 3.77 (2023-H1) to 3.59 (2024-H2)
- **82 employees** have 3+ reviews but have never been promoted — a sizeable at-risk group for attrition

### Projects
- **9 of 33 projects (27%)** are currently Delayed or Cancelled, spread fairly evenly across departments
- **55 employees** are allocated more than 300 hours across active projects — a workload concentration worth monitoring for burnout
- **HR's project spend is 360% of its allocated department budget** — the single biggest budget-overrun flag in the company, while Product (28%) and Engineering (50%) are comfortably under budget

---

## 📁 Repository Structure
```
├── nexacorp_hr_analysis.sql     # All 20 queries with business-question comments
├── departments.csv              # Department reference data
├── employees.csv                # Employee master data (with manager hierarchy)
├── salaries.csv                 # Salary history
├── performance_reviews.csv      # Performance review records
├── projects.csv                 # Project records
├── employee_projects.csv        # Employee-to-project assignments
└── README.md                    # Project overview (this file)
```

---

## 🚀 How to Run
1. Create a database: `CREATE DATABASE nexacorp_hr;`
2. Create all 6 tables (schema included as comments/DDL at the top of the queries file, or inferred from each CSV's header)
3. Import each CSV into its matching table using `LOAD DATA INFILE` or MySQL Workbench's Import Wizard, in this order: `departments → employees → salaries → performance_reviews → projects → employee_projects` (required due to foreign key dependencies)
4. Run the queries in `nexacorp_hr_analysis.sql` section by section

---

## 👤 Author
**[Ajay Sharma]**
📧 [dajaysharma99@gmail.com] | 🔗 [LinkedIn Profile]([https://www.linkedin.com/in/ajjuxy/) | 💻 [GitHub Profile](https://github.com/i-ajaysharma)
