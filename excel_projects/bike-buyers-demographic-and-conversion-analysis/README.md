---

## 📊 Module 2: Excel Interactive Dashboard — Bike Sales Demographics Analysis

### **Project Overview**
This project analyzes demographic factors influencing bicycle purchasing behavior across 1,000 customer records. It outlines the data cleaning workflow, dynamic Pivot Table modeling, and interactive dashboard creation within Microsoft Excel.

---

### **Key Data Cleaning & Transformation Steps**
1. **Deduplication:** Removed 26 duplicate rows from the raw `bike_buyers` dataset, standardizing the clean sample to 1,000 unique records in `working_sheet`.
2. **Value Standardization:** 
   - Standardized `Marital Status` (`M` $\rightarrow$ `Married`, `S` $\rightarrow$ `Single`).
   - Standardized `Gender` (`F` $\rightarrow$ `Female`, `M` $\rightarrow$ `Male`).
3. **Feature Engineering (`Age Brackets`):** Built a custom age classification column using nested logic:
   - `Adolescent`: Age $< 31$
   - `Middle Age`: Age $31 - 54$
   - `Old`: Age $\ge 55$

---

### **Key Insights & Metric Summary**

| Metric / Demographic | Non-Buyer (`No`) | Buyer (`Yes`) | Key Takeaway |
| :--- | :--- | :--- | :--- |
| **Total Customers** | 519 | 481 | Overall Conversion Rate: **48.10%** |
| **Average Income (Female)** | $53,440.00 | $55,774.06 | Higher income directly correlates with bike purchases |
| **Average Income (Male)** | $56,208.18 | $60,123.97 | Males show higher overall average spend capacity |
| **Top Age Bracket** | 318 | **383** | **Middle Age (31-54)** is the primary target segment |
| **0–1 Mile Commute** | 172 | **206** | Short commutes strongly drive purchasing decision |

---

### **Dashboard Features & Architecture**
- **Dynamic Pivot Tables (`pivot_table`):** Aggregates income, age, commute distance, and regional metrics segmented by `Purchased Bike`.
- **Interactive Slicers (`Dashboard`):** Includes visual slicers for **Marital Status**, **Region**, and **Education Level** connected to all pivot charts for real-time dynamic filtering.