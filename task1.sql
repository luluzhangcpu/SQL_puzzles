--第一题，将a表和b表 对应键连接起来，并取相对应的字段；
select a.id,a.price,b.sales 
from sp a left join product b on a.id = b.product_id;
