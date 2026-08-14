/*select 
ci.cst_id,
ci.cst_key,
ci.cst_firstname,
ci.cst_lastname,
ci.cst_marital_status,
ci.cst_gndr,
ci.cst_create_date,
ca.bdate,
ca.gen,
la.cntry
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
on ci.cst_key=ca.cid
left join silver.erp_loc_a101 la
on ci.cst_key=la.cid*/

--after joining tables,check if any duplicates were introduced by the join logic... so to do check no duplicates from result we need to group by:
/* select cst_id,count(*)from(select 
ci.cst_id,
ci.cst_key,
ci.cst_firstname,
ci.cst_lastname,
ci.cst_marital_status,
ci.cst_gndr,
ci.cst_create_date,
ca.bdate,
ca.gen,
la.cntry
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
on ci.cst_key=ca.cid
left join silver.erp_loc_a101 la
on ci.cst_key=la.cid)t group by cst_id having count(*)>1
*/


--ther's also two tables with diff data(cst_gend & gen) so we have to do data integration
--we need to ask expert about the master data is it CRM or ERP or checking urself
/*select distinct
ci.cst_gndr,
ca.gen,
case when ci.cst_gndr !='n/a' then ci.cst_gndr  --CRM is master
else coalesce(ca.gen,'n/a') end as new_gen     ---ERP is master
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
on ci.cst_key=ca.cid
left join silver.erp_loc_a101 la
on ci.cst_key=la.cid
order by 1,2*/



------ after that we need to see if it dimension or fact
--dimension hold descriptive info about an object,,we need to generate new primery key in DWH called(surrogate keys)
--only use it in order to connect/control our data modle,,we can generate it using window function(ROW_NUBER())
--row_number() over (order by cst_id) as customer_key,

--then create object and all objs in gold must be virual by use (views)

--after that we need to check for quality for gold table/new objs
--select * from gold.dim_customers
--select distinct gender from gold.dim_customers


--we need to build new obj(erp_px_cat_g1v2 and crm_prd_info)
/*select pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_line,
pn.prd_start_dt,
pn.prd_end_dt
from silver.crm_prd_info pn*/

--prd_end_dt has bad data
/*select pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_line,
pn.prd_start_dt,
pn.prd_end_dt
from silver.crm_prd_info pn
where prd_end_dt is null --filter out all historical data(means no duplicate each product has only one record)
*/

--then we have to join it with product_category erp_px_cat_g1v2

/*select pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_line,
pn.prd_start_dt,
pc.cat,
pc.subcat,
pc.maintenance
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
on pn.cat_id=pc.id*/

--next check for quality and uniquness of this result
/*select prd_key,count(*) from(
select pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_line,
pn.prd_start_dt,
pc.cat,
pc.subcat,
pc.maintenance
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
on pn.cat_id=pc.id
where prd_end_dt is null)t group by prd_key
having count(*)>1
*/

--have dimention or fact?? so we have onyly dimention-->each row describing one obj
--if it dimention then we need to make (surrogate key)primary key for it 
--used to connect data model
/*select 
row_number() over(order by pn.prd_start_dt,pn.prd_key) as product_key,
pn.prd_id,
pn.prd_key,
pn.prd_nm,
pn.cat_id,
pc.cat,
pc.subcat,
pc.maintenance,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
on pn.cat_id=pc.id
where prd_end_dt is null
*/
--then make view
--create view gold.dim_products as 
--then check everythings are right
--select * from gold.dim_products



--then next to sales,do we have dimension or fact?
--we see trasactions,events,dates info,measuers---> so its fact 
--we use surrogate keys that comes from dimentions instead of ids to connect facts with dimensions
--so by joining two dimensions order to get surrogate key this process called (data lookup)
select sd.sls_ord_num,
--sd.sls_prd_key,
pr.product_key,
--sd.sls_cust_id,
cu.customer_key,
sd.sls_order_dt,
sd.sls_ship_dt,
sd.sls_due_dt,
sd.sls_sales,
sd.sls_quantity,
sd.sls_price
from silver.crm_sales_details sd
left join gold.dim_products pr
on sd.sls_prd_key=pr.product_number 
left join gold.dim_customers cu
on sd.sls_cust_id=cu.customer_id

--so we have in our fact table two keys(customer_key,product_key) from dimensions and this can help us to connect data model
--to connect fact with dimensions,building fact table by put surrogate keys from dimensions in the facts
select
sd.sls_ord_num as order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt as order_date,
sd.sls_ship_dt as shipping_date,
sd.sls_due_dt as due_date,
sd.sls_sales as sales_amount,
sd.sls_quantity as quatity,
sd.sls_price as price
from silver.crm_sales_details sd
left join gold.dim_products pr
on sd.sls_prd_key=pr.product_number 
left join gold.dim_customers cu
on sd.sls_cust_id=cu.customer_id

--after we done we need to do fact check to see if all dimension tables can successfully join the fact table
select * 
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key=f.customer_key
left join gold.dim_products p
on p.product_key=f.product_key
where c.customer_key is null and p.product_key is null


