# 📊 Advanced SQL Analytics Project: Sales & Customer Intelligence

## 🧠 Overview

This project leverages SQL to perform **deep analytical reporting** on a simulated retail sales database (`gold.fact_sales`, `gold.dim_customers`, `gold.dim_products`) using advanced querying, KPIs, and data segmentation. The purpose is to extract **actionable business intelligence** around customer behavior, product performance, and sales trends.

---

## 📂 Datasets Used

| Table                | Description                                                                         |
| -------------------- | ----------------------------------------------------------------------------------- |
| `gold.fact_sales`    | Contains sales transactions with date, product, quantity, amount, and customer keys |
| `gold.dim_customers` | Customer demographic information                                                    |
| `gold.dim_products`  | Product metadata including category, subcategory, cost                              |

---

## 📌 Key Analyses & Features

### 📅 Time-Based Sales Analysis

* **Yearly & Monthly Trends:** Total sales, quantity sold, and new customer acquisition.
* **Cumulative Analysis:** Running totals and average price over time using window functions.
* **Monthly breakdown per year:** Combining `DATETRUNC` and aggregation for better granularity.

### 🧍‍♂️ Customer Analysis

* **Customer Segmentation:** Classified into `VIP`, `Regular`, or `New` based on lifespan and total spending.
* **Lifespan & Recency Metrics:** How long a customer has been active and how recently they purchased.
* **Average Order Value (AOV) & Monthly Spending:** Key KPIs for customer value assessment.
* **Age Grouping:** Categorized into `UNDER 20`, `20-29`, `30-39`, etc.

### 📦 Product Analysis

* **Product Segmentation:** Tagged as `High-Performer`, `Mid-Range`, or `Low-Performer` based on total sales.
* **Average Selling Price & Revenue KPIs:** Including AOR (Average Order Revenue), average monthly revenue.
* **Product Lifespan & Recency:** How long a product remained active and time since last sale.

### 📈 Performance Insights

* **Year-over-Year Comparison:** Sales growth/decline per product vs. historical averages.
* **Category Contribution:** Breakdown of total sales percentage by product category.
* **Trend Classification:** Labeled products and customers as `Increasing`, `Decreasing`, or `Stable`.

---

## 🏗️ Created Views

* `GOLD_CUSTOMER_REPORT`: A consolidated customer-level report with all KPIs and segments.
* `gold_report_products`: A product-level analytics report summarizing profitability, volume, and customer reach.

---

## 🔧 Technologies Used

* SQL Server (T-SQL syntax)
* Window functions (`OVER()`, `LAG()`, `AVG()`, `SUM()`)
* Common Table Expressions (CTEs)
* Views for reusable reporting
* Joins, Aggregations, and Date Functions

---

## 🎯 Business Value

This project provides a **360-degree view** of sales and customer data to support:

* Targeted marketing (e.g., reactivation of inactive VIPs)
* Product lifecycle optimization
* Strategic pricing and promotions
* Investor reporting & operational KPIs
