-- make new cleared tables
-- remove connections that do not exist in one or the other map
-- make new axial_cleared
-- make new rcl_cleared

-- create link layer

DROP TABLE IF EXISTS public.axial_rcl_links;

CREATE TABLE public.axial_rcl_links(
  id serial NOT NULL,
  id_axial integer,
  id_rcl integer,
  geom geometry(LINESTRING,27700),
  CONSTRAINT axial_rcl_links_pk PRIMARY KEY(id)
);

ALTER TABLE public.axial_rcl_links OWNER TO postgres;

CREATE INDEX axial_rcl_links_gist ON public.axial_rcl_links USING gist(geom);

TRUNCATE public.axial_rcl_links CASCADE;
-- find links

-- where the buffer of the bounding box intersects an axial line, ang angle approx. same and distance between midpoint and line < 15
INSERT INTO public.axial_rcl_links(id_axial, id_rcl, geom)
SELECT axial.id, rcl.id, ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom)
FROM axial_segment_map_m25 AS axial , london_ax_ex AS rcl
WHERE ST_Expand(axial.geom,15)&&rcl.geom
      AND abs(ST_Azimuth(ST_StartPoint(rcl.geom), ST_EndPoint(rcl.geom)) - ST_Azimuth(ST_StartPoint(axial.geom),ST_Endpoint(axial.geom))) < 0.25
      AND ST_Length(ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom)) < 15;
