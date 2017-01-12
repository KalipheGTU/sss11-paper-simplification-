-- make new cleared tables
-- remove connections that do not exist in one or the other map
-- make new axial_cleared
-- make new rcl_cleared

-- create link layer

CREATE TABLE sss11_simplification.axial_rcl_links(
  id serial NOT NULL,
  id_axial integer,
  id_rcl integer,
  geom geometry(LINESTRING,27700),
  CONSTRAINT axial_rcl_links_pk PRIMARY KEY(id)
)

ALTER TABLE sss11_simplification.axial_rcl_links OWNER TO postgres;

CREATE INDEX axial_rcl_links_gist ON sss11_simplification.axial_rcl_links USING gist(geom);



SELECT ST_MakeLine(ST_Centroid(axial.geom), ST_Centroid(rcl.geom))
FROM sss11_simplification.axial_map_m25 AS axial , sss11_simplification.open_roads_london AS rcl
WHERE ST_Intersects(axial.geom,rcl.geom) OR ST_DWithin(rcl.geom, axial.geom, 10)

CREATE TABLE t_intersect AS
SELECT
  hp.gid,
  hp.st_address,
  hp.city,
  hp.st_num,
  hp.the_geom
FROM
  public.housepoints AS hp LEFT JOIN
  public.parcel AS par ON
  ST_Intersects(hp.the_geom,par.the_geom)
WHERE par.gid IS NULL;
