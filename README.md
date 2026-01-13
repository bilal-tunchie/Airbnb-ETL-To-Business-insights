# 🏠 Airbnb Data Analysis – ETL to Power BI

## 📌 Project Overview
This project demonstrates an end-to-end ETL (Extract, Transform, Load) pipeline built to prepare Airbnb data for Power BI dashboards and business insights.
The goal of this project is to transform raw Airbnb data into clean, standardized, and business-ready datasets using SQL Server and pyhton, then consume the data in Power BI for visualization and analysis.

![Data Flow](https://samsung-crm.com/mena/KSA/Aseries_Nov5/Data-Flow.jpg)


## 📂 Data Source
- Dataset: Riyadh Airbnb
- Source: Kaggle

## 🔁 ETL Architecture
The ETL process follows a structured data flow:
Source → SQL Server → Power BI

## 1️⃣ Extract
- Raw CSV files downloaded from Kaggle
- Loaded into SQL Server as raw tables
- Stored as-is with no transformations
- Batch processing using full load & truncate/insert


## 2️⃣ Transform
Data cleaning and transformation were performed entirely using SQL and python, including:
- ✔️ Geo-reversing all adresses (city, province, district, postcode and street)
      using Latitude and longitude **(python geo-reversing using geopy)**
- ✔️ Checking and fixing column data types
- ✔️ Handling missing values (NULLs)
- ✔️ Standardizing values and formats
- ✔️ Creating property categories (Studio, Apartment, Hotel, etc.)
- ✔️ Filtering out invalid or inconsistent records
- ✔️ Renaming columns for clarity
- ✔️ Trimming and cleaning text fields
- ✔️ Removing unnecessary columns
- ✔️ Merging and appending related tables
- ✔️ Normalizing nested price items
- ✔️ Validating business logic (rooms, beds, revenue calculations)

  
- The result is a set of cleaned and standardized tables ready for analytics.

![Data Transform](https://samsung-crm.com/mena/KSA/241029_AR/Data-Transformation.jpg)


## 3️⃣ Load
- Final datasets exposed as SQL Views
- Views represent business-ready data
- No additional load required
- Optimized for Power BI consumption


## 🧱 Data Model
- Flat and aggregated tables
- Fact-style table


## 📊 Power BI
- Coming soon


## 🛠 Tools & Technologies
- SQL Server
- SQL (ETL & Data Transformation)
- Python (geopy and sqlalchemy)
- Power BI
- Kaggle
- GitHub


## 🎯 Key Learning Outcomes
- Building a real-world ETL pipeline
- Preparing data specifically for BI tools
- Applying data cleaning best practices
- Translating raw data into business-ready datasets
- Designing analytics-friendly SQL views


## 📌 Next Steps
- Enhance dashboards with advanced DAX measures
- Add time-based analysis
- Optimize performance with indexing
- Expand dataset with additional Airbnb attributes


## 🙌 Credits
- Dataset: Kaggle
- Analysis & ETL: Bilal Mohamed [Bilal Mohamed](https://www.linkedin.com/in/bilal-mohamed-909b95201/) 
- Data Engineer: [Mohammed Alsubaie](https://www.kaggle.com/datasets/mohammedalsubaie/riyadh-airbnb)



## 📂 Repository Structure
```
Airbnb-ETL-Dashboard-insights/
├── docs/                                            # Project documentation and architecture details
│   ├── Data Flow.drawio                             # Draw.io file shows the project's architecture
│   ├── Data Transform.drawio                        # Draw.io file shows the project's ETL Exapmles
│   ├── Data-Flow.jpg                                # Data Flow image
│   ├── Data-Transformation.jpg                      # Data Transformation image
│
│
├── Data/                                            # Raw and Cleaned datasets used for the project
│   ├── Cleaned Data                                 # Cleaned datasets used for the project
│   ├── Uncleaned Data                               # Raw datasets used for the project
│
│
├── scripts/                                         # SQL scripts for ETL and transformations
│   ├── 1-import_raw_data.sql/                       # Scripts for extracting and loading raw data
│   ├── 2-Fact_table.sql/                            # Scripts for cleaning and transforming data
│   ├── 3-price_items.sql/                           # Scripts for cleaning and transforming data
│   ├── 4-priceItems_offers_discounts_taxes.sql/     # Scripts for cleaning and transforming data
│   ├── 5-final_fact_view.sql/                       # Scripts for creating analytical models
│                          
└── README.md                                        # Project overview and instructions
```
---
