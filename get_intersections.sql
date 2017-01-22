DROP TABLE IF EXISTS sss11.osm_intersections;
CREATE TABLE sss11.osm_intersections(id serial, geom geometry(POINT,27700));

ALTER TABLE sss11.osm_intersections ADD PRIMARY KEY(id);
--CREATE INDEX sidx_intersections_geom ON _intersections USING gist (geom);

WITH all_endpoints AS (SELECT ST_StartPoint(a.geom) AS geom
                      FROM sss11.cleaned_osm AS a
                      UNION
                      SELECT ST_EndPoint(a.geom) AS geom
                      FROM sss11.cleaned_osm  AS a)
INSERT INTO sss11.osm_intersections(geom)
SELECT DISTINCT ON (geom) geom
FROM all_endpoints;
