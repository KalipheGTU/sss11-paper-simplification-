

SELECT DISTINCT ON (axial.id) axial.id, axial.geom
FROM axial_map_m25 AS axial , open_roads_london AS rcl
WHERE (ST_DWithin(ST_Centroid(axial.geom), rcl.geom, 10)


 OR ST_DWithin(ST_Centroid(rcl.geom), axial.geom, 10))
  OR (axial.geom&&rcl.geom AND NOT ST_Length(axial.geom) < 20 AND NOT ST_Length(rcl.geom) < 20)

--write new layer


SELECT DISTINCT ON (rcl.id) rcl.id, rcl.geom
FROM axial_map_m25 AS axial , open_roads_london AS rcl
WHERE (ST_DWithin(ST_Centroid(rcl.geom), axial.geom, 10) OR (ST_DWithin(ST_Centroid(axial.geom), rcl.geom, 10))
  OR (axial.geom&&rcl.geom AND NOT ST_Length(axial.geom) < 20 AND NOT ST_Length(rcl.geom) < 20)

--write new layer
