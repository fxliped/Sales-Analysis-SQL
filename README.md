# Sales-Analysis-SQL

In order for technology companies to maximize sales by allocating resources towards different products, towards marketing to different people, and picking up on sales missed by competing companies, data analysis must be used and to find out how this can be done. Using this example [Kaggle Dataset for consumer electronic sales](https://www.kaggle.com/datasets/rabieelkharoua/consumer-electronics-sales-dataset), the purpose of this project is to generate business insights using MySQL to potentially improve sales, improve marketing strategies, and improve customer satisfaction.

### About The Data

| Column  | Description |   Data Type   |
| ------------- | ------------- | ------------- |
| ProductID  | Unique Identifier for each product  | INT |
| ProductCategory  | Category of the consumer electronics product (e.g., Smartphones, Laptops)  | VARCHAR(20) |
| ProductBrand | Brand of the product (e.g., Apple, Samsung) | VARCHAR(20) |
| ProductPrice  | Price of the product in US dollars  | DECIMAL(10,2) |
| CustomerAge  | Age of the customer  | INT |
| CustomerGender | Gender of the customer (0 for male, 1 for female) | INT |
| PurchaseFrequency  | Average number of purchases per year for each individual product  | INT |
| CustomerSatisfaction  | Satisfaction rating given by the customers for the product (1-5)  | INT |
| PurchaseIntent | Whether the consumer purchased the product with the initial intent to buy the item (0 for no, 1 for yes) | INT |
