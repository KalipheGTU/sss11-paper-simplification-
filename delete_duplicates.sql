WITH unique_geoms (id, geom) as
 (SELECT row_number() OVER (PARTITION BY geom) as id, gid, geom FROM sss11.os_simpl10_5)
DELETE FROM sss11.os_simpl10_5 AS a
USING unique_geoms AS ug
WHERE ug. id<>1 AND ug.gid = a.gid;
