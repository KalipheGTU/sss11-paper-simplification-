ALTER TABLE sss11.cleaned_axial_segment
ADD COLUMN length float;

ALTER TABLE sss11.cleaned_os
DROP COLUMN IF EXISTS length,
ADD COLUMN length float;

ALTER TABLE sss11.cleaned_osm
ADD COLUMN length float;

ALTER TABLE sss11.cleaned_ssx
ADD COLUMN length float;

UPDATE  sss11.cleaned_axial_segment AS a
SET length = ST_Length(a.geom);
UPDATE  sss11.cleaned_os AS a
SET length = ST_Length(a.geom);
UPDATE  sss11.cleaned_osm AS a
SET length = ST_Length(a.geom);
UPDATE  sss11.cleaned_ssx AS a
SET length = ST_Length(a.geom);
