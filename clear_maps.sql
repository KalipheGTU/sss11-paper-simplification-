-- make new cleared tables
-- remove connections that do not exist in one or the other map
-- make new axial_cleared
-- make new rcl_cleared

-- create link layer

WITH cleared_features AS (SELECT axial.id AS axial_id, rcl.id AS rcl_id , axial.geom AS axial_geom, rcl.geom AS rcl_geom
                          FROM axial_map_m25 AS axial , open_roads_london AS rcl
                          WHERE ST_DWithin(ST_Centroid(axial.geom), rcl.geom, 10)
                          OR
                           ST_DWithin(ST_Centroid(rcl.geom), axial.geom, 10)
                          OR
                          (rcl.geom&&axial.geom AND ST_Length(axial.geom) > 15 AND ST_Length(rcl.geom) > 15))
SELECT DISTINCT ON (axial_id) axial_id, axial_geom
FROM cleared_features;
