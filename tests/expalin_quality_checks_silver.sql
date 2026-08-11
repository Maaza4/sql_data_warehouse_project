

/*check for nulls and duplicates in primary key*/
select cst_id,count(*) from bronze.crm_cust_info group by cst_id having count(*)>1 or cst_id is null

/*cleaning and remove duplicates by ranking  */
select * from (select * ,row_number() over (partition by cst_id order by cst_create_date desc) 
as flag_last from bronze.crm_cust_info where cst_id is not null)t where flag_last=1

/*Quality_Checks check for unwanted spaces if original name,status,gndr... != to trim query(nxt one) then there are spaces*/
select cst_firstname from bronze.crm_cust_info where cst_firstname !=trim(cst_firstname) 


select cst_id,cst_key,trim(cst_firstname)as cst_firstname,trim(cst_lastname) as cst_lastname,
cst_marital_status,cst_gndr,cst_create_date from(select * ,row_number() over (partition by cst_id order by cst_create_date desc) 
as flag_last from bronze.crm_cust_info where cst_id is not null)t where flag_last=1

--Data Standardization & Consistency
select distinct cst_gndr
from bronze.crm_cust_info

select distinct cst_marital_status
from bronze.crm_cust_info


/*check for nulls and duplicates in primary key*/
select cst_id,count(*) from bronze.crm_cust_info group by cst_id having count(*)>1 or cst_id is null

/*cleaning and remove duplicates by ranking  */
select * from (select * ,row_number() over (partition by cst_id order by cst_create_date desc) 
as flag_last from bronze.crm_cust_info where cst_id is not null)t where flag_last=1

/*Quality_Checks check for unwanted spaces if original name,status,gndr... != to trim query(nxt one) then there are spaces*/
select cst_firstname from bronze.crm_cust_info where cst_firstname !=trim(cst_firstname) 


/*select cst_id,cst_key,trim(cst_firstname)as cst_firstname,trim(cst_lastname) as cst_lastname,
cst_marital_status,cst_gndr,cst_create_date from(select * ,row_number() over (partition by cst_id order by cst_create_date desc) 
as flag_last from bronze.crm_cust_info where cst_id is not null)t where flag_last=1 */



  
--Data Standardization & Consistency
--fixing femal/male
select distinct cst_gndr
from silver.crm_cust_info
--fixing single/married
select distinct cst_marital_status 
from silver.crm_cust_info
select * from silver.crm_cust_info

--some values (M,S,T,R) unknown,need to rename
select distinct prd_line
from bronze.crm_prd_info

--check for nulls or negative numbers(use isnull() or coalesce())
select prd_cost from bronze.crm_prd_info where prd_cost < 0 or prd_cost is null

--check for invalid date orders(end date must not be earlier than start date)
--end_date=start_date of next record - 1
select * from bronze.crm_prd_info where prd_end_dt<prd_start_dt







/*////////////////////////////additonal prduct and customer details*/


/*check for prd_id no need to clean*/
select prd_id, count(*) from bronze.crm_prd_info group by prd_id having count(*)>1 or prd_id is null

/*apply transformation prd_key it contains 2 parts prd_key & cat_id, also '-','_' */
select distinct id from bronze.erp_px_cat_g1v2


select prd_id,prd_key,replace(substring(prd_key,1,5),'-','_' )as cat_id,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt
from bronze.crm_prd_info

/*filter out unmatched data after applying transformation*/
select prd_id,prd_key,replace(substring(prd_key,1,5),'-','_' )as cat_id,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt
from bronze.crm_prd_info where replace(substring(prd_key,1,5),'-','_' ) not in (select distinct id from bronze.erp_px_cat_g1v2)


select prd_id,prd_key,replace(substring(prd_key,1,5),'-','_' )as cat_id,substring(prd_key,7,len(prd_key)) as prd_key,
prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt
from bronze.crm_prd_info

/*prd_key associate with sls_prd_key */
select sls_prd_key from bronze.crm_sales_details









/*//////////////////////////////////////details on sales_details*/


--to see unwanted spaces
select sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity
,sls_price from bronze.crm_sales_details
where sls_ord_num !=trim(sls_ord_num)
--to see no issues in prd_key
select sls_prd_key from bronze.crm_sales_details where sls_prd_key not in (select prd_key from silver.crm_prd_info)
--see sls_cst
select sls_cust_id from bronze.crm_sales_details where sls_cust_id not in (select cst_id from silver.crm_cust_info)

--check for invalid dates
select sls_order_dt from bronze.crm_sales_details where sls_order_dt<=0

--to fix it 
select nullif(sls_order_dt,0) from bronze.crm_sales_details where sls_order_dt<=0

--check length of data must be 8
select nullif(sls_order_dt,0) from bronze.crm_sales_details where sls_order_dt<=0 or len(sls_order_dt)!=8

--check bounderies
select nullif(sls_order_dt,0) from bronze.crm_sales_details where sls_order_dt<=0 or len(sls_order_dt)!=8 or sls_order_dt >20500101 or sls_order_dt <19000101

--check order date must be early than shipping and due date
select sls_order_dt from bronze.crm_sales_details where sls_order_dt> sls_ship_dt or sls_order_dt>sls_due_dt


--data consistency:
--for sls_sales,sls_quantity,sls_price they are connected to other
--sales=quantity*price (not(-ve,zero,null,not allowed))
select distinct sls_sales,sls_quantity,sls_price from bronze.crm_sales_details 
where sls_sales != sls_quantity * sls_price or sls_sales is null or sls_quantity is null or sls_price is null 
or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0 

--if sales (-ve,zero,null,not allowed) derive it using quantity and price
--if price is zero,null calcu it using salse and quantity
--if price -ve convert it to +ve
select distinct sls_sales as old_sls_sales,sls_quantity,sls_price as old_sls_price,
case when sls_sales is null or sls_sales <=0 or sls_sales != sls_quantity * abs(sls_price)
then sls_quantity * abs(sls_price) else sls_sales end as sls_sales,
case when sls_price is null or sls_price <=0  then sls_sales / nullif(sls_quantity,0) else sls_price end as sls_price
from bronze.crm_sales_details 
where sls_sales != sls_quantity * sls_price or sls_sales is null or sls_quantity is null or sls_price is null 
or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0 









