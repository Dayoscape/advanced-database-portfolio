-- Q5: best rated products with at least 20 reviews
EXPLAIN (ANALYZE, BUFFERS)
SELECT r.product_id,
       count(*) AS review_count,
       round(avg(r.rating), 2) AS avg_rating
FROM reviews r
GROUP BY r.product_id
HAVING count(*) >= 20
ORDER BY avg_rating DESC, review_count DESC
LIMIT 10;
