# 💼 Sales and Customer Insights

## 🔍 Overview
This SQL script analyzes customer spending, order patterns, product revenue, discount impact, sales representative performance, and customer retention using the **AdventureWorks2019** database. The script includes various analytical queries to gain insights into sales trends and customer behavior.

## 🛠️ Features
### 1. 📊 Orders View - Aggregated Sales Data
- Creates a **view** named `Orders` that aggregates sales data per month, customer, and order ID.
- Includes total order amount, quantity, and count of orders.

### 2. 💰 Customer Spending Analysis
- Calculates total spending and total orders for each customer.
- Ranks customers by **total spending** within each month using `DENSE_RANK()`.

### 3. 🛍️ Order Pattern Analysis
- Calculates the **number of orders** placed each month.
- Uses `LAG()` function to compare the current month's order count with the previous month.
- Computes percentage change in orders.

### 4. 📈 Product Revenue Ranking
- Aggregates total revenue for each **product**.
- Ranks products by **total revenue** using `DENSE_RANK()`.

### 5. 💳 Average Order Value (AOV) Analysis
- Calculates the **average order value (AOV)** per customer.
- Ranks customers by AOV within each month.

### 6. 💸 Discount Impact on Sales
- Categorizes orders as **Discounted** or **Non-Discounted** based on `SpecialOfferID`.
- Computes **total discounted amount** for each order.

### 7. 🧑‍💼 Sales Representative Performance
- Evaluates **sales rep performance** by calculating **total sales** and **commission earned**.
- Ranks sales reps based on total sales.

### 8. 🔄 Customer Retention Analysis
- Calculates **repeat purchases**, **average days between purchases**, and **customer churn status**.
- Identifies `Active` and `Churned` customers based on last purchase date.

**Sofo Qaadze**  
📧 sqaadze2000@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/sofo-qaadze-ba7895205/)
