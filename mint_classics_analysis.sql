use mintclassics;

SELECT * FROM offices;

-- What is the current inventory level in each warehouse, and are there significant variations across them?
SELECT 
    w.warehousecode,
    w.warehousepctcap,
    SUM(o.quantityordered) AS sum_ordered_quantity,
    SUM(p.quantityInStock) AS sum_quantity_instock
FROM
    products p
        JOIN
    warehouses w ON p.warehousecode = w.warehousecode
        JOIN
    orderdetails o ON p.productcode = o.productcode
GROUP BY 1 , 2
ORDER BY 3 DESC , 4 DESC;

-- Which product lines have higher/lower demand, and can adjustments be made in the inventory based on this analysis?
SELECT 
    p.productline,
    p.warehousecode,
    SUM(p.quantityinstock) AS sum_quantity_instock,
    SUM(o.quantityordered) AS sum_ordered_quantity
FROM
    products p
        JOIN
    productlines pl ON p.productline = pl.productline
        JOIN
    orderdetails o ON p.productcode = o.productcode
GROUP BY 1 , 2
ORDER BY 2 , 3 DESC , 4 DESC;

-- Are there specific sales representatives who have a higher impact on certain product sales?
SELECT 
    e.employeenumber,
    p.productname,
    p.productline,
    SUM(od.quantityordered) AS ordered_quantity
FROM
    employees e
        JOIN
    customers c ON e.employeenumber = c.salesrepemployeenumber
        JOIN
    orders o ON o.customernumber = c.customernumber
        JOIN
    orderdetails od ON o.ordernumber = od.ordernumber
        JOIN
    products p ON p.productcode = od.productcode
GROUP BY 1 , 2 , 3
ORDER BY 1 , 4 DESC;

-- Are there customers with lower credit limits, and how does this impact inventory turnover?
SELECT 
    customernumber,
    CASE
        WHEN total_amount >= credit_limit THEN 'low credit limit'
        ELSE 'high credit limit'
    END AS credit_limit_status
FROM (SELECT 
    distinct c.customernumber, sum(p.amount) over(partition by c.customernumber) as total_amount, c.creditlimit as credit_limit
FROM
    payments p
        JOIN
    customers c ON p.customernumber = c.customernumber
ORDER BY 2 DESC , 3 DESC)
    customer_credit;

-- How quickly are orders processed and shipped, and are there bottlenecks affecting timely service?
SELECT 
    *
FROM
    orders
WHERE
    requireddate < shippeddate;
SELECT 
    w.warehousecode, COUNT(*) AS bad_service
FROM
    products p
        JOIN
    warehouses w ON p.warehousecode = w.warehousecode
        JOIN
    orderdetails o ON p.productcode = o.productcode
        JOIN
    orders od ON o.ordernumber = od.ordernumber
WHERE
    requireddate < shippeddate
GROUP BY warehousecode;

-- How can the warehouses be optimized to accommodate inventory changes without affecting operational efficiency?
SELECT 
    w.warehousecode,
    w.warehousepctcap,
    SUM(p.quantityinstock) AS instock,
    ROUND((SUM(p.quantityinstock) * 100 / w.warehousepctcap),
            2) AS totalcapacity,
    ROUND(((100 - w.warehousepctcap) / w.warehousepctcap) * SUM(p.quantityinstock),
            2) AS remainingcapacity
FROM
    warehouses w
        JOIN
    products p ON w.warehousecode = p.warehousecode
GROUP BY 1 , 2
ORDER BY 3 DESC , 4 DESC;

-- Are there product lines that can be expanded or reduced based on historical sales data and market trends?
SELECT 
    p.productline,
    YEAR(o.orderdate),
    SUM(od.quantityordered) AS ordered_quantity
FROM
    orders o
        JOIN
    orderdetails od ON o.ordernumber = od.ordernumber
        JOIN
    products p ON p.productcode = od.productcode
GROUP BY 1 , 2
ORDER BY 2 , 3 DESC;

-- What is the turnover rate for different products?
SELECT 
    productline, SUM(total_price) AS total_product_price
FROM
    (SELECT 
        p.productline,
            p.productcode,
            SUM(od.quantityordered * od.priceeach) AS total_price
    FROM
        orderdetails od
    JOIN products p ON p.productcode = od.productcode
    GROUP BY 1 , 2
    ORDER BY 3 DESC) product_price
GROUP BY 1
ORDER BY 2 DESC;
