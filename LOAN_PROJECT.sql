-- I. PREPARING DATA
CREATE DATABASE Report;
 
CREATE TABLE report (
	id INT PRIMARY KEY, 			-- ID of clients
    age INT, 						-- The age of client 
    income DOUBLE,					-- The income of client per year
    employment_year DOUBLE,			-- The number of years the client has been employed
    married INT, 					-- Marriage status (0. single and 1.married)
    dependent INT, 					-- The number of dependents the client has
    loan_amount DOUBLE, 			-- The amount of loan requested by the client
    loan_term INT, 					-- The duration of the loan in years 
    credit_score DOUBLE, 			-- A numerical representation of the client’s creditworthiness 
    existing_loan INT,				-- The current number of loans client have to pay
    debt_to_income DOUBLE, 			-- Debt to income ratio
    payment_history INT, 			-- Payment history review (0. poor and 1. good)
    loan_purpose TEXT, 				-- The reason for applying for the loan
    approval INT 					-- Approval status (0. rejected and 1. approved)
    );

-- FILTERING DATA 
DELETE FROM report WHERE age - employment_year <= 12;
DELETE FROM report WHERE income < 9700;
DELETE FROM report WHERE loan_amount < 10500;
   
SELECT *
FROM report
LIMIT 5;

SELECT COUNT(*)
FROM report;

--  II. OVERVIEW: 
-- 1. Average of loan application metrics: 
CREATE VIEW y_AVG AS
SELECT 
	'AVG_approved' AS '###',
	ROUND(AVG(age),3) age,
    ROUND(AVG(income),3) income,
    ROUND(AVG(employment_year),3) employment_year,
    ROUND(AVG(dependent),3) dependent,
    ROUND(AVG(loan_amount),3) loan_amount,
    ROUND(AVG(loan_term),3) loan_term,
    ROUND(AVG(credit_score),3) credit_score,
    ROUND(AVG(existing_loan),3) existing_loan,
    ROUND(AVG(debt_to_income),3) debt_to_income
FROM report
WHERE approval = 1; 

CREATE VIEW n_AVG AS
SELECT 
	'AVG_rejected' AS '###',
	ROUND(AVG(age),3) age,
    ROUND(AVG(income),3) income,
    ROUND(AVG(employment_year),3) employment_year,
    ROUND(AVG(dependent),3) dependent,
    ROUND(AVG(loan_amount),3) loan_amount,
    ROUND(AVG(loan_term),3) loan_term,
    ROUND(AVG(credit_score),3) credit_score,
    ROUND(AVG(existing_loan),3) existing_loan,
    ROUND(AVG(debt_to_income),3) debt_to_income
FROM report
WHERE approval = 0;

SELECT * FROM y_AVG
UNION ALL
SELECT * FROM n_AVG;

-- 2.Do people with good credit scores tend to borrow more? 
SELECT 
	CASE 
		WHEN credit_score < 550 THEN '1. Extreme Low: < 550 ' 
		WHEN credit_score BETWEEN 550 AND 650 THEN '2. Low: 550 - 650' 
		WHEN credit_score BETWEEN 651 AND 750 THEN '3. Medium: 651: 750'
		ELSE '4. High: > 750' 
    END credit_range, 
    ROUND(AVG(debt_to_income),3) AVGdti,
    COUNT(id) number
FROM report
WHERE payment_history = 1
GROUP BY credit_range
ORDER BY credit_range;

-- 3. New metric new_dti: DTI (debt-to-income) after borrowing
-- 			new_dti 		= ( income 	* 	debt_to_income + loan_amount / loan_term) / income 
CREATE VIEW newdti AS
SELECT
	*,
	ROUND((income * debt_to_income + (loan_amount / NULLIF(loan_term, 0))) / NULLIF(income, 0),3) AS new_dti
FROM report;
SELECT
    CASE
            WHEN new_dti < 0.2 THEN '1. Safe: < 0.2'
            WHEN new_dti BETWEEN 0.2 AND 0.6 THEN '2. Low: 0.2 - 0.6'
            WHEN new_dti BETWEEN 0.7 AND 1 THEN '3. Medium: 0.7 - 1'
            WHEN new_dti BETWEEN 1.1 AND 2 THEN '4. High: 1.1 - 2'
            ELSE '5. Risk: > 2' 
	END AS new_debt_to_income_group,
	ROUND(AVG(loan_amount),3) total_loan,
	COUNT(id) number
FROM newdti
WHERE approval = 1
GROUP BY new_debt_to_income_group
ORDER BY new_debt_to_income_group; 

-- 4. Common loan purposes by age group
with age_scale AS (
    SELECT
        id,
        loan_amount,
        credit_score,
        loan_purpose,
        approval,
        CASE
            WHEN age < 25 THEN '1. Under 25'
            WHEN age BETWEEN 25 AND 35 THEN '2. 25-35'
            WHEN age BETWEEN 36 AND 45 THEN '3. 36-45'
            WHEN age BETWEEN 46 AND 55 THEN '4. 46-55'
            WHEN age BETWEEN 56 AND 65 THEN '5. 56-65'
            ELSE '6. Above 65'
        END AS age_scale
    FROM report
),
purpose_rank AS (
    SELECT
        age_scale,
        loan_purpose,
        ROW_NUMBER() OVER (PARTITION BY age_scale  ORDER BY COUNT(*) DESC, loan_purpose) AS rn
    FROM age_scale
    GROUP BY age_scale, loan_purpose
),
AVG AS (
    SELECT
        age_scale,
        ROUND(AVG(loan_amount),3) AS AVG_loan_amount,
        ROUND(AVG(credit_score),3) AS AVG_credit_score,
        COUNT(*) AS total_loans
    FROM age_scale
    WHERE approval = 1
    GROUP BY age_scale
)
SELECT
    a.age_scale,
    a.AVG_loan_amount,
    a.AVG_credit_score,
    a.total_loans,
    k.loan_purpose AS most_common_loan_purpose
FROM AVG a
JOIN purpose_rank k
ON a.age_scale = k.age_scale 
WHERE k.rn = 1
ORDER BY a.age_scale;

-- III. Factors
-- SAFETY FACTORS
-- 	+ Financial factors: income, credit_score, history_payment, existing_loan, debt_to_income
-- 	+ Demographic factors: age, employment_year, married, dependent
-- PROFITABILITY FACTORS
--  + Loan factor : loan_amount, loan_term, loan_purpose
-- 5. Are age and marital status important factors in the evaluation criteria? 
SELECT 
	CASE 
		WHEN age BETWEEN 18 AND 25 THEN '18-25'
		WHEN age BETWEEN 26 AND 35 THEN '26-35'
		WHEN age BETWEEN 36 AND 45 THEN '36-45'
		WHEN age BETWEEN 46 AND 55 THEN '46-55'
        WHEN age BETWEEN 56 AND 65 THEN '56-65'
		ELSE 'over 65' 
	END AS age_scale,
	SUM(CASE WHEN approval = 1 AND married = 1 THEN 1 ELSE 0 END) AS married_approved,
	SUM(CASE WHEN approval = 1 AND married = 0 THEN 1 ELSE 0 END) AS unmarried_approved,
	SUM(CASE WHEN approval = 0 AND married = 1 THEN 1 ELSE 0 END) AS married_rejected,
	SUM(CASE WHEN approval = 0 AND married = 0 THEN 1 ELSE 0 END) AS unmarried_rejected
FROM report
GROUP BY age_scale
ORDER BY age_scale;

-- 6. Is a good payment history considered a positive factor ?
SELECT 
	CASE 
		WHEN loan_amount BETWEEN 0 AND 100000 THEN '1. Small: 0 - 100.000'
		WHEN loan_amount BETWEEN 100001 AND 200000 THEN '2. Medium: 100.001 - 200.000'
		ELSE '3. Large: Over 200.000' 
	END AS loan_amount_scale,
	SUM(CASE WHEN approval = 1 AND payment_history = 1 THEN 1 ELSE 0 END) AS paid_approved,
	SUM(CASE WHEN approval = 1 AND payment_history = 0 THEN 1 ELSE 0 END) AS unpaid_approved,
	SUM(CASE WHEN approval = 0 AND payment_history = 1 THEN 1 ELSE 0 END) AS paied_rejected,
	SUM(CASE WHEN approval = 0 AND payment_history = 0 THEN 1 ELSE 0 END) AS unpaid_rejected
FROM report
GROUP BY loan_amount_scale
ORDER BY loan_amount_scale;

-- The optimal state is the average value in approval group add more 5%. 
-- 7. In the optimal state of demographic factors, do financial factors still influence rejection decisions? 
SELECT COUNT(*)
FROM report r
CROSS JOIN y_AVG AVG
WHERE r.approval = 0
	AND r.age BETWEEN 36 AND 55
    AND r.employment_year >= 0.95*AVG.employment_year
	AND r.depENDent <= 1.05*AVG.depENDent;
    
-- 8. In the optimal state of financial factors, do demographic factors still influence rejection decisions?
SELECT COUNT(*)
FROM report r
CROSS JOIN y_AVG avg
WHERE r.approval = 0
	AND r.payment_history = 1
	AND r.income >= 0.95*avg.income
	AND r.credit_score >= 0.95*avg.credit_score
	AND r.existing_loan <= 1.05*avg.existing_loan
	AND r.debt_to_income <= 1.05*avg.debt_to_income;

-- *Even under optimal conditions of safety factors (both demographic and financial), 
-- would profitability factors influence rejection decisions?
SELECT COUNT(*)
FROM report r
CROSS JOIN y_AVG AVG
WHERE r.approval = 0
	AND r.age BETWEEN 36 AND 55
    AND r.employment_year >= 0.95*AVG.employment_year
	AND r.dependent <= 1.05*AVG.dependent
    AND r.payment_history = 1
	AND r.income >= 0.95*AVG.income
	AND r.credit_score >= 0.95*AVG.credit_score
	AND r.existing_loan <= AVG.existing_loan
	AND r.debt_to_income <= AVG.debt_to_income;
    
-- 9. In the optimal state of profitability factors, do safety factors still influence rejection decisions?
SELECT COUNT(*)
FROM newdti n
CROSS JOIN y_AVG AVG
WHERE n.approval = 0
	AND n.loan_amount >= 0.95*AVG.loan_amount
    AND n.loan_term <= 1.05*AVG.loan_term
	AND n.new_dti >= 0.95*(SELECT AVG(new_dti) FROM newdti WHERE approval = 1);

-- III. IDENTIFING THE GREY AREA
-- 10. List of potential customers who were not approved: 
-- Raise the thresholds up to 20%
CREATE VIEW grey_area AS
SELECT r.*
FROM newdti r
CROSS JOIN y_AVG AVG
WHERE approval = 0
	AND payment_history = 1
	AND r.employment_year >= AVG.employment_year
	AND r.dependent <= 1.2*AVG.dependent
	AND r.income >= 0.8*AVG.income
	AND r.credit_score >= 0.8*AVG.credit_score
	AND r.existing_loan <= 1.2*AVG.existing_loan
	AND r.debt_to_income <= 1.2*AVG.debt_to_income
    AND new_dti <= 1.2*(SELECT AVG(new_dti) FROM newdti WHERE approval = 1)
ORDER BY new_dti DESC, r.income DESC;
SELECT *
FROM grey_area;

-- *Comparing the average values in grey_area and y_AVG:
SELECT 
	'grey_area' AS '###',
	ROUND(AVG(age),3) age,
    ROUND(AVG(income),3) income,
    ROUND(AVG(employment_year),3) employment_year,
    ROUND(AVG(depENDent),3) depENDent,
    ROUND(AVG(loan_amount),3) loan_amount,
    ROUND(AVG(loan_term),3) loan_term,
    ROUND(AVG(credit_score),3) credit_score,
    ROUND(AVG(existing_loan),3) existing_loan,
    ROUND(AVG(debt_to_income),3) debt_to_income
FROM grey_area
UNION ALL
SELECT * 
FROM y_AVG;

-- END

