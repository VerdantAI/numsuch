DROP TABLE IF EXISTS r.yummly_names;
CREATE TABLE r.yummly_names AS
SELECT
  ingredient
, row_number() OVER (ORDER BY ingredient) AS ftr_id
FROM r.yummly_recipe
GROUP BY ingredient;
// Build edges
DROP TABLE IF EXISTS r.yummly_edges;
CREATE TABLE r.yummly_edges AS
SELECT
  a.lfid AS from_fid
, b.rfid AS to_fid
, count(*) AS w
FROM (
  SELECT
    l.recipe_id AS lr, l.ingredient AS li, ln.ftr_id AS lfid
  FROM r.yummly_recipe AS l
  INNER JOIN r.yummly_names AS ln
    ON l.ingredient = ln.ingredient
) AS a
INNER JOIN
(
  SELECT
    l.recipe_id AS lr, l.ingredient AS li, ln.ftr_id AS rfid
  FROM r.yummly_recipe AS l
  INNER JOIN r.yummly_names AS ln
    ON l.ingredient = ln.ingredient
) AS b
  ON a.lr = b.lr
GROUP BY a.lfid, b.rfid
;
