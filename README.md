# SQL Data Warehouse (Bronze / Silver / Gold)

A SQL Server data warehouse that combines sales data from two source systems (CRM and ERP) into a star schema for reporting. It uses the Medallion Architecture: raw data in **Bronze**, cleaned data in **Silver**, and business-ready views in **Gold**.

Built with **SQL Server Express, T-SQL and SSMS**.

---

## Credits

This project is based on the **[SQL Data Warehouse Project](https://github.com/DataWithBaraa/sql-data-warehouse-project)** tutorial by **Data With Baraa** (MIT License). The datasets, layer design and most of the ETL logic come from that tutorial. My own changes are listed under [What I changed](#what-i-changed).

---

## Architecture

```
CSV files (CRM + ERP)
        ↓  BULK INSERT
Bronze  – raw tables, loaded as-is
        ↓  clean, standardise, fix types
Silver  – cleaned tables
        ↓  join + model
Gold    – star schema views (dim_customers, dim_products, fact_sales)
```

### Table names by layer

Bronze and Silver use the same names, prefixed by source system (`crm_` or `erp_`). Gold uses `dim_` and `fact_`.

| Source | Bronze | Silver | Gold |
|---|---|---|---|
| CRM customers | `bronze.crm_cust_info` | `silver.crm_cust_info` | `gold.dim_customers` |
| ERP customers | `bronze.erp_cust_az12` | `silver.erp_cust_az12` | `gold.dim_customers` |
| ERP locations | `bronze.erp_loc_a101` | `silver.erp_loc_a101` | `gold.dim_customers` |
| CRM products | `bronze.crm_prd_info` | `silver.crm_prd_info` | `gold.dim_products` |
| ERP categories | `bronze.erp_px_cat_g1v2` | `silver.erp_px_cat_g1v2` | `gold.dim_products` |
| CRM sales | `bronze.crm_sales_details` | `silver.crm_sales_details` | `gold.fact_sales` |

### Main Silver-layer cleaning

- Keeps only the latest record per customer (`ROW_NUMBER()` on `cst_id`)
- Trims names and maps codes to readable values (`M` → `Male`, `S` → `Single`, `R` → `Road`)
- Converts integer dates (`20121229`) to `DATE` and sets invalid ones to `NULL`
- Recalculates sales when `sales ≠ quantity × price` or values are missing or negative
- Builds product end dates from the next start date, so Gold can keep only current products

---

## Business Insights

These results come from [`scripts/analysis/business_insights.sql`](scripts/analysis/business_insights.sql), run on the loaded warehouse.

**Overall:** 60,398 order lines · 27,659 orders · 18,484 customers · **29.36M** total revenue · orders from Dec 2010 to Jan 2014.

**1. Bikes bring in almost all the revenue.**

| Category | Revenue | Share |
|---|---:|---:|
| Bikes | 28,316,272 | 96.5% |
| Accessories | 700,262 | 2.4% |
| Clothing | 339,716 | 1.2% |

**2. Australia earns about as much as the US with half the customers.**

| Country | Customers | Revenue | Revenue per customer |
|---|---:|---:|---:|
| United States | 7,482 | 9,162,327 | 1,224 |
| Australia | 3,591 | 9,060,172 | **2,523** |
| United Kingdom | 1,913 | 3,391,376 | 1,772 |
| Germany | 1,780 | 2,894,066 | 1,625 |
| France | 1,810 | 2,643,751 | 1,460 |
| Canada | 1,571 | 1,977,738 | 1,258 |

**3. The top 5 products are all Mountain-200 bikes.** Each one earned between 1.29M and 1.37M.

**4. Revenue grew 2.8× in 2013.** Revenue went from 5.84M in 2012 to 16.34M in 2013. Units sold went from 3,397 to 52,807, and active customers went from 3,255 to 17,427. Cheaper accessories and clothing were first sold at the end of December 2012, which explains most of the jump in units. (2010 and 2014 contain only a few weeks of data.)

---

## What I changed

Compared with the original tutorial code:

- **Configurable dataset path.** The tutorial's `bronze.load_bronze` hard-codes the CSV folder. I added an `@dataset_path` parameter and switched to dynamic `BULK INSERT`, so the procedure works on any machine without editing the code:
  ```sql
  EXEC bronze.load_bronze @dataset_path = 'C:\path\to\DATA-WAREHOUSEING\datasets\';
  ```
- **Analysis queries.** I added `scripts/analysis/business_insights.sql`, which answers questions about category share, revenue per customer by country, top products and yearly trend. The README reports the actual results.
- **Repo clean-up.** I gave all scripts the `.sql` extension and kept them in one `scripts/` folder. I also fixed wrong header comments, such as the Silver DDL header that said "bronze".
- **Comments.** I added notes in the scripts on the order to run them and what each step does.

---

## Repository structure

```
DATA-WAREHOUSEING/
├── datasets/
│   ├── source_crm/          # cust_info, prd_info, sales_details
│   └── source_erp/          # CUST_AZ12, LOC_A101, PX_CAT_G1V2
├── scripts/
│   ├── init_database.sql    # creates DataWarehouse DB + schemas
│   ├── bronze/              # ddl_bronze.sql, proc_load_bronze.sql
│   ├── silver/              # ddl_silver.sql, proc_load_silver.sql
│   ├── gold/                # ddl_gold.sql (star schema views)
│   └── analysis/            # business_insights.sql
├── tests/                   # quality_checks_silver.sql, quality_checks_gold.sql
└── README.md
```

---

## How to run

You need SQL Server (Express is fine) and SSMS.

1. Clone the repo.
   ```bash
   git clone https://github.com/Sanjay5704/DATA-WAREHOUSEING.git
   ```
2. Run `scripts/init_database.sql`. **Warning:** this drops and recreates the `DataWarehouse` database.
3. Run `scripts/bronze/ddl_bronze.sql` and `scripts/bronze/proc_load_bronze.sql`, then load the data:
   ```sql
   EXEC bronze.load_bronze @dataset_path = 'C:\path\to\DATA-WAREHOUSEING\datasets\';
   ```
   The SQL Server service account needs read access to that folder.
4. Run `scripts/silver/ddl_silver.sql` and `scripts/silver/proc_load_silver.sql`, then:
   ```sql
   EXEC silver.load_silver;
   ```
5. Run `scripts/gold/ddl_gold.sql`.
6. Run the checks in `tests/` and the queries in `scripts/analysis/`.

---

## Limitations

- Full reload each time (no incremental loads)
- No history tracking (no slowly changing dimensions); Gold keeps only current products

---

## Author

**Sanjay Sathish Kumar** · [GitHub](https://github.com/Sanjay5704) · [LinkedIn](https://www.linkedin.com/in/sanjaysathishkumar)

## License

MIT
