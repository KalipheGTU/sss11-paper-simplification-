CREATE TABLE sss11.os_simpl (gid integer,geom geometry(LINESTRING,27700));
INSERT INTO  sss11.os_simpl
SELECT  gid, ST_SimplifyPreserveTopology(geom,10) AS geom
FROM sss11.cleaned_os;

-- delete points
