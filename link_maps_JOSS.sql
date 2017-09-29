-- algorithm to link the different street network maps
-- for comparison of centrality values
-- for the JOSS article


-- link axial to unmodified OS
-- DROP TABLE IF EXISTS joss_links.axial_os_links;
CREATE TABLE joss_links.axial_os_links(
  id serial NOT NULL,
  axial_id integer,
  rcl_ids integer[],
  rcl_count integer,
  axial_length double precision,
  sum_rcl_length double precision,
  max_choice800 integer,
	max_choice1200 integer,
	max_choice2000 integer,
	max_choice3200 integer,
	max_choice5000 integer,
	max_choicen integer,
  avg_int800 double precision,
	avg_int1200 double precision,
	avg_int2000 double precision,
  avg_int3200 double precision,
	avg_int5000 double precision,
	avg_intn double precision,
  geom geometry(MULTILINESTRING,27700),
  CONSTRAINT axial_os_links_pk PRIMARY KEY(id)
);
-- make links
-- TRUNCATE joss_links.axial_os_links;
WITH links AS (
		SELECT rcl.id AS rcl_id, rcl.length AS rcl_length,
			axial.id AS axial_id, axial.length AS axial_length,
			ST_Length(ST_ShortestLine(axial.centroid, rcl.geom)) AS length,
      ST_ShortestLine(axial.centroid, rcl.geom) AS geom
		FROM
			(SELECT axial_p.id, geom, ST_Centroid(geom) AS centroid, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			FROM joss_simpl.axial_p) AS axial,
			(SELECT id, geom, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			 FROM joss_simpl.os_p) AS rcl
    WHERE ST_Dwithin(axial.centroid, rcl.geom, 15)
    AND abs(axial.azimuth_c - rcl.azimuth_c) < 0.25
)
INSERT INTO joss_links.axial_os_links(
   	axial_id,  rcl_ids, rcl_count, axial_length, sum_rcl_length, geom,
    max_choice800, max_choice1200, max_choice2000, max_choice3200, max_choice5000, max_choicen,
    avg_int800, avg_int1200, avg_int2000, avg_int3200, avg_int5000, avg_intn)
  SELECT links.axial_id,
		array_agg(links.rcl_id),
		count(*),
		links.axial_length,
		sum(links.rcl_length),
		ST_Collect(links.geom),
  	max(rcl."T1024_Choice_R800_metric"),
		max(rcl."T1024_Choice_R1200_metric"),
		max(rcl."T1024_Choice_R2000_metric"),
		max(rcl."T1024_Choice_R3200_metric"),
		max(rcl."T1024_Choice_R5000_metric"),
		max(rcl."T1024_Choice"),
		avg(rcl."T1024_Integration_R800_metric"),
		avg(rcl."T1024_Integration_R1200_metric"),
		avg(rcl."T1024_Integration_R2000_metric"),
		avg(rcl."T1024_Integration_R3200_metric"),
		avg(rcl."T1024_Integration_R5000_metric"),
		avg(rcl."T1024_Integration")
	FROM links, joss_simpl.os_p AS rcl
	WHERE links.rcl_id = rcl.id
	GROUP BY links.axial_id, links.axial_length
;
-- make links further out (25) to nearest and only for axial lines with no match
WITH links AS (
		SELECT DISTINCT(axial.id) AS axial_id,
			rcl.id AS rcl_id,
			rcl.length AS rcl_length,
			axial.length AS axial_length,
			ST_Length(ST_ShortestLine(axial.centroid, rcl.geom)) AS length,
      ST_ShortestLine(axial.centroid, rcl.geom) AS geom
		FROM
			(SELECT axial_p.id, geom, ST_Centroid(geom) AS centroid, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			FROM joss_simpl.axial_p
			WHERE id NOT IN (SELECT axial_id FROM joss_links.axial_os_links)
			) AS axial,
			(SELECT id, geom, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			 FROM joss_simpl.os_p) AS rcl
    WHERE ST_Dwithin(axial.centroid, rcl.geom, 25)
    AND abs(axial.azimuth_c - rcl.azimuth_c) < 0.25
		ORDER BY ST_Length(ST_ShortestLine(axial.centroid, rcl.geom)) ASC
)
INSERT INTO joss_links.axial_os_links(
   	axial_id,  rcl_ids, rcl_count, axial_length, sum_rcl_length, geom,
    max_choice800, max_choice1200, max_choice2000, max_choice3200, max_choice5000, max_choicen,
    avg_int800, avg_int1200, avg_int2000, avg_int3200, avg_int5000, avg_intn)
  SELECT links.axial_id,
		array_agg(links.rcl_id),
		count(*),
		links.axial_length,
		sum(links.rcl_length),
		ST_Collect(links.geom),
  	max(rcl."T1024_Choice_R800_metric"),
		max(rcl."T1024_Choice_R1200_metric"),
		max(rcl."T1024_Choice_R2000_metric"),
		max(rcl."T1024_Choice_R3200_metric"),
		max(rcl."T1024_Choice_R5000_metric"),
		max(rcl."T1024_Choice"),
		avg(rcl."T1024_Integration_R800_metric"),
		avg(rcl."T1024_Integration_R1200_metric"),
		avg(rcl."T1024_Integration_R2000_metric"),
		avg(rcl."T1024_Integration_R3200_metric"),
		avg(rcl."T1024_Integration_R5000_metric"),
		avg(rcl."T1024_Integration")
	FROM links, joss_simpl.os_p AS rcl
	WHERE links.rcl_id = rcl.id
	GROUP BY links.axial_id, links.axial_length
;
CREATE INDEX axial_os_links_geom_idx ON joss_links.axial_os_links USING gist(geom);


-- link axial to simplified (Douglas-Peuker) OS
-- DROP TABLE IF EXISTS joss_links.axial_os_dp_links;
CREATE TABLE joss_links.axial_os_dp_links(
  id serial NOT NULL,
  axial_id integer,
  rcl_ids integer[],
  rcl_count integer,
  axial_length double precision,
  sum_rcl_length double precision,
  max_choice800 integer,
	max_choice1200 integer,
	max_choice2000 integer,
	max_choice3200 integer,
	max_choice5000 integer,
	max_choicen integer,
  avg_int800 double precision,
	avg_int1200 double precision,
	avg_int2000 double precision,
  avg_int3200 double precision,
	avg_int5000 double precision,
	avg_intn double precision,
  geom geometry(MULTILINESTRING,27700),
  CONSTRAINT axial_os_dp_links_pk PRIMARY KEY(id)
);
-- make links
-- TRUNCATE joss_links.axial_os_dp_links;
WITH links AS (
		SELECT rcl.id AS rcl_id, rcl.length AS rcl_length,
			axial.id AS axial_id, axial.length AS axial_length,
			ST_Length(ST_ShortestLine(axial.centroid, rcl.geom)) AS length,
      ST_ShortestLine(axial.centroid, rcl.geom) AS geom
		FROM
			(SELECT axial_p.id, geom, ST_Centroid(geom) AS centroid, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			FROM joss_simpl.axial_p) AS axial,
			(SELECT id, geom, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			 FROM joss_simpl.os_dp_p) AS rcl
    WHERE ST_Dwithin(axial.centroid, rcl.geom, 15)
    AND abs(axial.azimuth_c - rcl.azimuth_c) < 0.25
)
INSERT INTO joss_links.axial_os_dp_links(
   	axial_id,  rcl_ids, rcl_count, axial_length, sum_rcl_length, geom,
    max_choice800, max_choice1200, max_choice2000, max_choice3200, max_choice5000, max_choicen,
    avg_int800, avg_int1200, avg_int2000, avg_int3200, avg_int5000, avg_intn)
  SELECT links.axial_id,
		array_agg(links.rcl_id),
		count(*),
		links.axial_length,
		sum(links.rcl_length),
		ST_Collect(links.geom),
  	max(rcl."T1024_Choice_R800_metric"),
		max(rcl."T1024_Choice_R1200_metric"),
		max(rcl."T1024_Choice_R2000_metric"),
		max(rcl."T1024_Choice_R3200_metric"),
		max(rcl."T1024_Choice_R5000_metric"),
		max(rcl."T1024_Choice"),
		avg(rcl."T1024_Integration_R800_metric"),
		avg(rcl."T1024_Integration_R1200_metric"),
		avg(rcl."T1024_Integration_R2000_metric"),
		avg(rcl."T1024_Integration_R3200_metric"),
		avg(rcl."T1024_Integration_R5000_metric"),
		avg(rcl."T1024_Integration")
	FROM links, joss_simpl.os_dp_p AS rcl
	WHERE links.rcl_id = rcl.id
	GROUP BY links.axial_id, links.axial_length
;
-- make links further out (25) to nearest and only for axial lines with no match
WITH links AS (
		SELECT DISTINCT(axial.id) AS axial_id,
			rcl.id AS rcl_id,
			rcl.length AS rcl_length,
			axial.length AS axial_length,
			ST_Length(ST_ShortestLine(axial.centroid, rcl.geom)) AS length,
      ST_ShortestLine(axial.centroid, rcl.geom) AS geom
		FROM
			(SELECT axial_p.id, geom, ST_Centroid(geom) AS centroid, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			FROM joss_simpl.axial_p
			WHERE id NOT IN (SELECT axial_id FROM joss_links.axial_os_links)
			) AS axial,
			(SELECT id, geom, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			 FROM joss_simpl.os_dp_p) AS rcl
    WHERE ST_Dwithin(axial.centroid, rcl.geom, 25)
    AND abs(axial.azimuth_c - rcl.azimuth_c) < 0.25
		ORDER BY ST_Length(ST_ShortestLine(axial.centroid, rcl.geom)) ASC
)
INSERT INTO joss_links.axial_os_dp_links(
   	axial_id,  rcl_ids, rcl_count, axial_length, sum_rcl_length, geom,
    max_choice800, max_choice1200, max_choice2000, max_choice3200, max_choice5000, max_choicen,
    avg_int800, avg_int1200, avg_int2000, avg_int3200, avg_int5000, avg_intn)
  SELECT links.axial_id,
		array_agg(links.rcl_id),
		count(*),
		links.axial_length,
		sum(links.rcl_length),
		ST_Collect(links.geom),
  	max(rcl."T1024_Choice_R800_metric"),
		max(rcl."T1024_Choice_R1200_metric"),
		max(rcl."T1024_Choice_R2000_metric"),
		max(rcl."T1024_Choice_R3200_metric"),
		max(rcl."T1024_Choice_R5000_metric"),
		max(rcl."T1024_Choice"),
		avg(rcl."T1024_Integration_R800_metric"),
		avg(rcl."T1024_Integration_R1200_metric"),
		avg(rcl."T1024_Integration_R2000_metric"),
		avg(rcl."T1024_Integration_R3200_metric"),
		avg(rcl."T1024_Integration_R5000_metric"),
		avg(rcl."T1024_Integration")
	FROM links, joss_simpl.os_dp_p AS rcl
	WHERE links.rcl_id = rcl.id
	GROUP BY links.axial_id, links.axial_length
;
CREATE INDEX axial_os_dp_links_geom_idx ON joss_links.axial_os_dp_links USING gist(geom);



-- link axial to simplified OS with urban paths
-- DROP TABLE IF EXISTS joss_links.axial_os_paths_links;
CREATE TABLE joss_links.axial_os_paths_links(
  id serial NOT NULL,
  axial_id integer,
  rcl_ids integer[],
  rcl_count integer,
  axial_length double precision,
  sum_rcl_length double precision,
  max_choice800 integer,
	max_choice1200 integer,
	max_choice2000 integer,
	max_choice3200 integer,
	max_choice5000 integer,
	max_choicen integer,
  avg_int800 double precision,
	avg_int1200 double precision,
	avg_int2000 double precision,
  avg_int3200 double precision,
	avg_int5000 double precision,
	avg_intn double precision,
  geom geometry(MULTILINESTRING,27700),
  CONSTRAINT axial_os_paths_links_pk PRIMARY KEY(id)
);
-- make links
-- TRUNCATE joss_links.axial_os_paths_links;
WITH links AS (
		SELECT rcl.id AS rcl_id, rcl.length AS rcl_length,
			axial.id AS axial_id, axial.length AS axial_length,
			ST_Length(ST_ShortestLine(axial.centroid, rcl.geom)) AS length,
      ST_ShortestLine(axial.centroid, rcl.geom) AS geom
		FROM
			(SELECT axial_p.id, geom, ST_Centroid(geom) AS centroid, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			FROM joss_simpl.axial_p) AS axial,
			(SELECT id, geom, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			 FROM joss_simpl.os_paths_p) AS rcl
    WHERE ST_Dwithin(axial.centroid, rcl.geom, 15)
    AND abs(axial.azimuth_c - rcl.azimuth_c) < 0.25
)
INSERT INTO joss_links.axial_os_paths_links(
   	axial_id,  rcl_ids, rcl_count, axial_length, sum_rcl_length, geom,
    max_choice800, max_choice1200, max_choice2000, max_choice3200, max_choice5000, max_choicen,
    avg_int800, avg_int1200, avg_int2000, avg_int3200, avg_int5000, avg_intn)
  SELECT links.axial_id,
		array_agg(links.rcl_id),
		count(*),
		links.axial_length,
		sum(links.rcl_length),
		ST_Collect(links.geom),
  	max(rcl."T1024_Choice_R800_metric"),
		max(rcl."T1024_Choice_R1200_metric"),
		max(rcl."T1024_Choice_R2000_metric"),
		max(rcl."T1024_Choice_R3200_metric"),
		max(rcl."T1024_Choice_R5000_metric"),
		max(rcl."T1024_Choice"),
		avg(rcl."T1024_Integration_R800_metric"),
		avg(rcl."T1024_Integration_R1200_metric"),
		avg(rcl."T1024_Integration_R2000_metric"),
		avg(rcl."T1024_Integration_R3200_metric"),
		avg(rcl."T1024_Integration_R5000_metric"),
		avg(rcl."T1024_Integration")
	FROM links, joss_simpl.os_paths_p AS rcl
	WHERE links.rcl_id = rcl.id
	GROUP BY links.axial_id, links.axial_length
;
-- make links further out (25) to nearest and only for axial lines with no match
WITH links AS (
		SELECT DISTINCT(axial.id) AS axial_id,
			rcl.id AS rcl_id,
			rcl.length AS rcl_length,
			axial.length AS axial_length,
			ST_Length(ST_ShortestLine(axial.centroid, rcl.geom)) AS length,
      ST_ShortestLine(axial.centroid, rcl.geom) AS geom
		FROM
			(SELECT axial_p.id, geom, ST_Centroid(geom) AS centroid, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			FROM joss_simpl.axial_p
			WHERE id NOT IN (SELECT axial_id FROM joss_links.axial_os_links)
			) AS axial,
			(SELECT id, geom, ST_Length(geom) AS length,
         (least(ST_Azimuth(ST_StartPoint(geom), ST_EndPoint(geom))::numeric,
						 ST_Azimuth(ST_EndPoint(geom), ST_StartPoint(geom))::numeric)-pi())
					 AS azimuth_c
			 FROM joss_simpl.os_paths_p) AS rcl
    WHERE ST_Dwithin(axial.centroid, rcl.geom, 25)
    AND abs(axial.azimuth_c - rcl.azimuth_c) < 0.25
		ORDER BY ST_Length(ST_ShortestLine(axial.centroid, rcl.geom)) ASC
)
INSERT INTO joss_links.axial_os_paths_links(
   	axial_id,  rcl_ids, rcl_count, axial_length, sum_rcl_length, geom,
    max_choice800, max_choice1200, max_choice2000, max_choice3200, max_choice5000, max_choicen,
    avg_int800, avg_int1200, avg_int2000, avg_int3200, avg_int5000, avg_intn)
  SELECT links.axial_id,
		array_agg(links.rcl_id),
		count(*),
		links.axial_length,
		sum(links.rcl_length),
		ST_Collect(links.geom),
  	max(rcl."T1024_Choice_R800_metric"),
		max(rcl."T1024_Choice_R1200_metric"),
		max(rcl."T1024_Choice_R2000_metric"),
		max(rcl."T1024_Choice_R3200_metric"),
		max(rcl."T1024_Choice_R5000_metric"),
		max(rcl."T1024_Choice"),
		avg(rcl."T1024_Integration_R800_metric"),
		avg(rcl."T1024_Integration_R1200_metric"),
		avg(rcl."T1024_Integration_R2000_metric"),
		avg(rcl."T1024_Integration_R3200_metric"),
		avg(rcl."T1024_Integration_R5000_metric"),
		avg(rcl."T1024_Integration")
	FROM links, joss_simpl.os_paths_p AS rcl
	WHERE links.rcl_id = rcl.id
	GROUP BY links.axial_id, links.axial_length
;
CREATE INDEX axial_os_paths_links_geom_idx ON joss_links.axial_os_paths_links USING gist(geom);
