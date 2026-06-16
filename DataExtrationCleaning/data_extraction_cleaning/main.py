"""
===========================================================
Customer Loyalty EDA Project
===========================================================

DESCRIPTION:
------------
This project performs Exploratory Data Analysis (EDA) on a customer shopping behavior dataset.
The goal is to analyze customer loyalty, spending patterns, and purchasing behavior.

The script:
1. Loads customer data from a CSV file
2. Cleans and preprocesses the dataset
3. Creates new features for analysis
4. Maps categorical values into numerical form
5. Stores the cleaned dataset into a SQL Server database

-----------------------------------------------------------

TECH STACK:
-----------
- Python (Pandas)
- SQL Server (via pyodbc + SQLAlchemy)
- Data Analysis / EDA techniques

-----------------------------------------------------------

DATASET:
--------
Input File: customer_shopping_behavior.csv

Make sure the file is placed in the same directory as this script.

-----------------------------------------------------------

HOW TO RUN:
-----------
1. Install required libraries:
   pip install pandas pyodbc sqlalchemy

2. Make sure SQL Server is running:
   - Server: localhost\SQLEXPRESS
   - Database: customer_behavior (must exist)

3. Run the script:
   python main.py

-----------------------------------------------------------

OUTPUT:
-------
- Cleaned dataset stored in SQL Server table:
  customer_behavior.customer_behavior

-----------------------------------------------------------
AUTHOR:
-------
[Youssif Mossad]
DATE:
-----
[6/16/2026]
===========================================================
"""
import pandas as pd 
import pyodbc
from sqlalchemy import create_engine
cx=pd.read_csv('customer_shopping_behavior.csv')
print(cx.head(5))
print(cx.shape)
print(cx.info())
print(cx.describe(include='all'))
#before Grouping
print(cx.isna().sum())
# print('*'*40)
# print(cx.duplicated().sum())
#Grouping the data by 'Category' and calculating the median of 'Review Rating' for each category, then filling the missing values in 'Review Rating' with the corresponding median value for each category.
cx['Review Rating']=cx.groupby('Category')['Review Rating'].transform(lambda x:x.median())
#After Grouping
print(cx.isna().sum())
#we will right the columns name in snake
cx.columns=cx.columns.str.lower() #Lower case all names 
cx.columns=cx.columns.str.replace(' ','_')# removing space and replcae by '_'
print(cx.isna().sum())
#we will change purchase amount usd column name into purchase amount 
cx=cx.rename(columns={"purchase_amount_(usd)":'purchase_amount'})
print(cx.columns)
#creating a new column "age grouped" based on the age into 4 groups 
label=['young-adult','adult','middle-aged','senior']
cx["age_grouped"]=pd.qcut(cx['age'],q=4,labels=label)
print(cx.head(5))

frequency_purchases={
    "Fortnightly" : 14 ,
    "Weekly" : 7,
    "Monthly" : 30,
    "Annually" : 365,
    "Quarterly" : 90,
    "Bi-Weekly" : 14,
    "Every 3 Months" : 90
}
cx['frequency_of_purchases']=cx['frequency_of_purchases'].map(frequency_purchases)
print(cx.head(5))

cx.drop('promo_code_used',axis=1,inplace=True)
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=customer_behavior;"
    "Trusted_Connection=yes;"
)

cursor = conn.cursor()
print("Connected")


engine = create_engine("mssql+pyodbc://localhost\\SQLEXPRESS/customer_behavior?driver=ODBC+Driver+17+for+SQL+Server&Trusted_Connection=yes")
cx.to_sql('customer_behavior', con=engine, if_exists='replace', index=False)
