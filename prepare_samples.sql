-- prepare sample points and buffers
-- for the JOSS article


-- create 200 random points (only works in PostGIS 2.3 and above)
-- DROP TABLE IF EXISTS joss_sources.random_points_nodist CASCADE;
CREATE TABLE joss_sources.random_points_nodist(
  id SERIAL NOT NULL,
  geom GEOMETRY(MultiPoint,27700),
  CONSTRAINT random_points_nodist_pk PRIMARY KEY(id)
);
WITH buffer AS (
  SELECT st_buffer(st_convexhull(geom),-3000) AS geom
  FROM joss_sources.axial_map_m25
)
INSERT INTO joss_sources.random_points_nodist (geom)
  SELECT st_generatepoints(buffer.geom, 200)
  FROM buffer
;
CREATE INDEX random_points_nodist_geom_idx
  ON joss_sources.random_points_nodist USING GIST (geom);

-- select 200 random locations from the NPTG data set
-- DROP TABLE IF EXISTS joss_sources.random_locations CASCADE;
CREATE TABLE joss_sources.random_locations AS
  SELECT *
  FROM (SELECT locations.*
    FROM
      joss_sources.nptg_localities AS locations,
      joss_sources.buffer AS buffer
    WHERE ST_Intersects(locations.geom, buffer.geom)) AS sample
  ORDER BY random()
  LIMIT 200
;
ALTER TABLE joss_sources.random_locations
  ADD CONSTRAINT random_locations_pk PRIMARY KEY(id);
CREATE INDEX random_locations_geom_idx
  ON joss_sources.random_locations USING GIST (geom);

-- select locations closest to the random points with 3km minimum distance (made in QGIS)
-- DROP TABLE IF EXISTS joss_sources.random_locations_3km CASCADE;
CREATE TABLE joss_sources.random_locations_3km AS
  SELECT *
  FROM joss_sources.nptg_localities
  WHERE id IN (
    SELECT (SELECT locations.id
      FROM joss_sources.nptg_localities AS locations
      ORDER BY locations.geom <#> points.geom
      LIMIT 1)
    FROM joss_sources.random_points_3km AS points)
;
-- an alternative method for the above
CREATE TABLE joss_sources.random_locations_3km AS
  SELECT DISTINCT ON(nearest.id) *
  FROM (
    SELECT DISTINCT ON (points.id)
      points.id                                   point_id,
      locations.*,
      ST_Distance(locations.geom, points.geom) AS dist
    FROM joss_sources.nptg_localities AS locations,
      joss_sources.random_points_3km AS points
    WHERE ST_DWithin(locations.geom, points.geom, 5000)
    ORDER BY points.id, ST_Distance(locations.geom, points.geom)
  ) nearest
;
ALTER TABLE joss_sources.random_locations_3km
  ADD CONSTRAINT random_locations_3km_pk PRIMARY KEY(id);
CREATE INDEX random_locations_3km_geom_idx
  ON joss_sources.random_locations_3km USING GIST (geom);

-- select locations closest to the random points with 1km minimum distance (made in QGIS)
-- DROP TABLE IF EXISTS joss_sources.random_locations_1km CASCADE;
CREATE TABLE joss_sources.random_locations_1km AS
  SELECT DISTINCT ON(nearest.id) *
  FROM (
    SELECT DISTINCT ON (points.id)
      points.id AS point_id,
      locations.*,
      ST_Distance(locations.geom, points.geom) AS dist
    FROM joss_sources.nptg_localities AS locations,
      joss_sources.random_points_1km AS points
    WHERE ST_DWithin(locations.geom, points.geom, 5000)
    ORDER BY points.id, ST_Distance(locations.geom, points.geom)
  ) nearest
;
ALTER TABLE joss_sources.random_locations_1km
  ADD CONSTRAINT random_locations_1km_pk PRIMARY KEY(id);
CREATE INDEX random_locations_1km_geom_idx
  ON joss_sources.random_locations_1km USING GIST (geom);

-- create sampling buffers using the random locations min 1km
-- modify the points source accordingly
-- DROP TABLE IF EXISTS joss_links.sampling_buffers CASCADE;
CREATE TABLE joss_links.sampling_buffers AS
  SELECT id, ST_Buffer(geom, 3000) geom, "LocalityName" AS place_name
  FROM joss_sources.random_locations_1km
;
ALTER TABLE joss_links.sampling_buffers
  ADD CONSTRAINT sampling_buffers_pk PRIMARY KEY(id);
CREATE INDEX sampling_buffers_geom_idx
  ON joss_links.sampling_buffers USING GIST (geom);
