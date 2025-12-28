# LOAN REJECTION FACTORS ANALYSIS PROJECT

## OVERVIEW

This project analyzes factors influencing loan rejection using a loan applications dataset.  
It identifies patterns in approved/rejected loans and suggests policy improvements.  
Analysis uses SQL; results presented in a report.  

**SOURCE**: https://www.kaggle.com/datasets/ckskaggle/loan-approval-data (train dataset)  

**Author**: Tran Duy Cuong  

## FILES

- LOAN_PROJECT.sql: SQL script for preparation/analysis.  
- LOAN_PROJECT.CSV: cleaned data file.  
- LOAN_PROJECT.pdf: 18-page report with tables/charts.  
- LOAN_PROJECT_VIETNAMESE.pdf: 18-page report with tables/charts by VietNamese.  

**Tools**: SQL (MySQL-compatible).  

## PROJECT WORKFLOW

## 1. Preparing Data

**Objective**: Setup, import, clean, and review data.  

**Steps**:  
- Create Report database and table with 14 fields.  
- Import data.  
- Filter invalid: age - employment_year <=12, income <9700, loan_amount <10500.  
- Verify: Preview top rows and count records.  

**Output**: Cleaned table with field descriptions.  

## 2. Overview

**Objective**: Basic insights on approved/rejected loans.  

**Steps**:  
- Compute averages: Views for approved/rejected metrics; union for comparison.  
- Credit scores/borrowing: Group by score ranges; avg debt-to-income for good history.  
- New metric new_dti: View for post-borrowing ratio; group approved by levels.  
- Loan purposes by age: CTEs for age groups, purpose ranking, averages.  

**Key Insights**:  
- Approved: Higher income/credit than rejected.  
- High credit correlates with more borrowing/higher debt-to-income.  
- Approved favor low new_dti (0.2-0.6) for repayment.  
- Purposes vary: Education for young/old; business/debt consolidation for 25-65.  

## 3. Factors Assessment

**Objective**: Evaluate rejection factors, interactions, constraints.  

**Steps**:  
- Categorize: Safety (financial/demographic), Profitability (loan).  
- Specific: Group age/marital for counts; loan amount/payment history.  
- Constraints: Optimal as approved avg ±5%; query rejected exceeding thresholds to rank strength.  

**Key Insights**:  
- Age 36-55 most approved; marriage no impact.  
- Good payment history strong positive (6x in approved).  
- Constraints: Financial > Demographic > Loan; Safety > Profitability.  

## 4. Identifying the Gray Area

**Objective**: Find reconsiderable rejections.  

**Steps**:  
- Combine safety with new_dti; raise thresholds 5 to 20%.  
- View for rejected near optimal, ordered by new_dti/income.  
- Compare gray area averages to approved.  

**Key Insights**: Gray cases exist; refine criteria for sales boost.  

## 5. Conclusion and Recommendations

- All factors influence (except marriage); finance key.  
- Prioritize business/debt consolidation.  
- Re-evaluate criteria for improvements.  
