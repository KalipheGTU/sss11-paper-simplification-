INSERT INTO public.axial_rcl_links(id_axial, id_rcl, geom)
SELECT axial.id, rcl.id, ST_MakeLine(ST_Line_Interpolate_Point(axial.geom, 0.5), ST_Line_Interpolate_Point(rcl.geom,0.5))
FROM axial_segment_map_m25 AS axial , london_ax_ex AS rcl
WHERE axial.geom&&rcl.geom AND ST_DWithin(ST_Line_Interpolate_Point(axial.geom, 0.5), ST_Line_Interpolate_Point(rcl.geom,0.5), 10);

INSERT INTO public.axial_rcl_links(id_axial, id_rcl, geom)
SELECT axial.id, rcl.id, ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom)
FROM axial_segment_map_m25 AS axial , london_ax_ex AS rcl
WHERE axial.geom&&rcl.geom AND ST_Length(ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom)) < 10;

INSERT INTO public.axial_rcl_links(id_axial, id_rcl, geom)
SELECT axial.id, rcl.id, ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom)
FROM axial_segment_map_m25 AS axial , london_ax_ex AS rcl
WHERE axial.geom&&rcl.geom AND ST_Length(ST_ShortestLine(ST_Line_Interpolate_Point(rcl.geom, 0.5), axial.geom)) < 10;

INSERT INTO public.axial_rcl_links(id_axial, id_rcl, geom)
SELECT axial.id, rcl.id, ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom)
FROM axial_segment_map_m25 AS axial , london_ax_ex AS rcl
WHERE ST_Length(axial.geom) < ST_Length(rcl.geom) AND ST_DWithin(ST_StartPoint(axial.geom),rcl.geom,10) AND ST_DWithin(ST_EndPoint(axial.geom),rcl.geom,10);

INSERT INTO public.axial_rcl_links(id_axial, id_rcl, geom)
SELECT axial.id, rcl.id, ST_ShortestLine(ST_Line_Interpolate_Point(axial.geom, 0.5), rcl.geom)
FROM axial_segment_map_m25 AS axial , london_ax_ex AS rcl
WHERE axial.geom&&rcl.geom AND ST_Buffer(ST_Line_Interpolate_Point(rcl.geom,0.5),15)&&rcl.geom;
