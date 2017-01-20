CREATE TABLE axial_map_m25_cropped AS
SELECT axial.id, axial.geom
FROM axial_map_m25 AS axial, n_s_boundary AS bo
WHERE axial.geom&&bo.geom;
