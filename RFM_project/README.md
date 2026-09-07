# End-to-End E-Commerce RFM Segmentation & Analytics

## Project Overview
This project processes transaction-level e-commerce data (`Online Retail II` dataset) to build an **RFM (Recency, Frequency, Monetary)** customer segmentation model. 

* **Database Engine:** MySQL 8.0+ (Data Cleaning, Transformation & Feature Engineering)
* **Reporting Layer:** Microsoft Excel / Power Query (Interactive Dashboards & Slicers)

---

## Technical Workflow & Micro-Steps

### Phase 1: Data Ingestion & Staging
* **Step 1.1:** Load raw transaction data (`online_retail_ii`) into MySQL.
* **Step 1.2:** Inspect table schema, total row counts, and data types (`DESCRIBE raw_online_retail;`).
* **Step 1.3:** Create a clean staging table (`online_retail_staging`) in a single pass to optimize query execution speed:
  * Filter out missing or blank `CustomerID` records (`WHERE CustomerID IS NOT NULL`).
  * Remove cancellation records (`Invoice LIKE 'C%'`) and non-positive quantities (`Quantity > 0`).
  * Exclude zero-price giveaways and bad data (`Price > 0`).
  * Explicitly cast `CustomerID` to `UNSIGNED INT`.
  * Pre-compute `TotalLineAmount = Quantity * UnitPrice`.

---

### Phase 2: Raw RFM Metric Extraction
* **Step 2.1:** Identify the global dataset max date and derive an anchor point (`MAX(InvoiceDate) + 1 DAY`).
* **Step 2.2:** Execute `GROUP BY CustomerID` to aggregate raw metrics per user:
  * **Recency:** `DATEDIFF(anchor_date, MAX(InvoiceDate))`
  * **Frequency:** `COUNT(DISTINCT Invoice)`
  * **Monetary Value:** `SUM(TotalLineAmount)`
* **Step 2.3:** Handle strict MySQL mode (`ONLY_FULL_GROUP_BY`) using inline subqueries for scalar date calculations.

---

### Phase 3: NTILE(4) Quartile Scoring & Segmentation
* **Step 3.1:** Apply SQL window functions (`NTILE(4) OVER (...)`) to categorize metrics into relative quartiles (Scores 1 to 4):
  * `r_score`: Ordered by `recency_days DESC` (fewer days = higher score).
  * `f_score`: Ordered by `frequency_orders ASC` (more orders = higher score).
  * `m_score`: Ordered by `monetary_value ASC` (higher spend = higher score).
* **Step 3.2:** Concatenate scores into an RFM cell identifier (e.g., `'4-4-4'`).
* **Step 3.3:** Map composite scores into business segments using conditional `CASE WHEN` logic:
  * **Champions:** `4-4-4`
  * **Loyal Customers:** High Recency & Frequency (`R >= 3`, `F >= 3`)
  * **Promising / New:** High Recency, Low Frequency (`R >= 3`, `F < 3`)
  * **At Risk:** Moderate/Low Recency, High Frequency (`R = 2`, `F >= 2`)
  * **Can't Lose Them:** Lowest Recency, High Frequency/Spend (`R = 1`, `F >= 3`)
  * **Lost:** Lowest scores across all metrics (`R = 1`, `F < 3`)

---

### Phase 4: Data Validation & Export
* **Step 4.1:** Verify distribution metrics per segment (customer counts, average spend, total revenue generated) to ensure no unexpected nulls or ties skewing bins.
* **Step 4.2:** Establish a live database connection in Excel via **Power Query** (`Data -> Get Data -> From Database -> From MySQL Database`).
* **Step 4.3:** Import the finalized `rfm_segmented` view/table into Excel's Data Model.

---

### Phase 5: Excel Visualization & Dashboard Setup
* **Step 5.1:** Construct Pivot Tables tracking:
  * Total Revenue by Segment.
  * Customer Count distribution per Segment.
  * Average Monetary Value vs. Recency Days.
* **Step 5.2:** Add interactive timeline filters and Segment Slicers.
* **Step 5.3:** Build executive visual charts (Bar/Donut) for marketing campaign targeting.