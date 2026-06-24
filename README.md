# Task B – Product Replenishment Priority Assessment

## Student Information
- Name: KELVIN IDOKO  
- Student Number: N01777723 

---

## Problem Summary
This project builds a SQL Server solution to assess product replenishment priority in Adventure Works. It classifies products as Urgent, Monitor Closely, or No Action based on inventory, manufacturing, and sales data.

---

## Solution Overview
Two objects were created in the `RetailAnalytics` schema:

- Scalar Function: calculates replenishment score  
- Stored Procedure: validates product, calls function, and returns priority result

---

## Execution Steps
1. Run Solution Script in AdventureWorks2022  
2. Run Test Script (TC1–TC5)  
3. View results, messages, and return codes  

---

## Assumptions
- AdventureWorks2022 is available  
- No changes made to base tables  
- Valid ProductID used for testing  