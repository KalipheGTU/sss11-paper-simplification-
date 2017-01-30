-- make new cleared tables
-- remove connections that do not exist in one or the other map
-- make new axial_cleared
-- make new rcl_cleared

-- create link layer

DROP TABLE IF EXISTS public.axial_rcl_links;
CREATE TABLE sss11_links.axial_rcl_links(
  id serial NOT NULL,
  id_axial integer,
  id_rcl integer,
  geom geometry(LINESTRING,27700),
  CONSTRAINT axial_rcl_links_pk PRIMARY KEY(id)
);

ALTER TABLE sss11_links.axial_rcl_links OWNER TO postgres;
CREATE INDEX axial_rcl_links_gist ON public.axial_rcl_links USING gist(geom);

DROP TABLE IF EXISTS public.rcl_axial_links;
CREATE TABLE public.rcl_axial_links(
  id serial NOT NULL,
  id_rcl integer,
  id_axial integer,
  geom geometry(LINESTRING,27700),
  CONSTRAINT rcl_axial_links_pk PRIMARY KEY(id)
);

ALTER TABLE public.rcl_axial_links OWNER TO postgres;
CREATE INDEX rcl_axial_links_gist ON public.rcl_axial_links USING gist(geom);

TRUNCATE public.axial_rcl_links CASCADE;
TRUNCATE public.rcl_axial_links CASCADE;

-- where the buffer of the bounding box intersects an axial line, ang angle approx. same and distance between midpoint and line < 15
INSERT INTO public.axial_rcl_links(id_axial, id_rcl, geom)
SELECT axial.id, rcl.id, ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom)
FROM axial_segment_map_m25 AS axial , london_ax_ex AS rcl
WHERE ST_Expand(axial.geom,15)&&rcl.geom
      AND abs(ST_Azimuth(ST_StartPoint(rcl.geom), ST_EndPoint(rcl.geom)) - ST_Azimuth(ST_StartPoint(axial.geom),ST_Endpoint(axial.geom))) < 0.25
      AND ST_Length(ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom)) < 15
      AND ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom) <> ST_MakeLine(ST_Line_Interpolate_Point(axial.geom, 0.5), ST_StartPoint(rcl.geom)
      AND ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom) <> ST_MakeLine(ST_Line_Interpolate_Point(axial.geom, 0.5), ST_EndPoint(rcl.geom);

-- where the buffer of the bounding box intersects an axial line, ang angle approx. same and distance between midpoint and line < 15
INSERT INTO public.rcl_axial_links(id_axial, id_rcl, geom)
SELECT rcl.id, axial.id, ST_ShortestLine(ST_Line_Interpolate_Point(rcl.geom, 0.5), axial.geom)
FROM axial_segment_map_m25 AS axial , london_ax_ex AS rcl
WHERE ST_Expand(rcl.geom,15)&&axial.geom
      AND abs(ST_Azimuth(ST_StartPoint(axial.geom), ST_EndPoint(axial.geom)) - ST_Azimuth(ST_StartPoint(rcl.geom),ST_Endpoint(rcl.geom))) < 0.25
      AND ST_Length(ST_ShortestLine(ST_Line_Interpolate_Point(rcl.geom, 0.5), axial.geom)) < 15
      AND ST_ShortestLine(ST_Line_Interpolate_Point(rcl.geom, 0.5), axial.geom) <> ST_MakeLine(ST_Line_Interpolate_Point(rcl.geom, 0.5), ST_StartPoint(axial.geom)
      AND ST_ShortestLine(ST_Line_Interpolate_Point(rcl.geom, 0.5), axial.geom) <> ST_MakeLine(ST_Line_Interpolate_Point(rcl.geom, 0.5), ST_EndPoint(axial.geom);
