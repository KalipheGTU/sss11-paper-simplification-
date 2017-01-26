
layer_1_name =
layer_2_name =
link_layer_1_name =
link_layer_2_name =
link_layer_name =
path = None
path_csv =

def getLayerByName(name):
	layer = None
	for i in QgsMapLayerRegistry.instance().mapLayers().values():
		if i.name() == name:
			layer = i
	return layer

layer_1 = getLayerByName(layer_1_name)
layer_2 = getLayerByName(layer_2_name)
link_layer_1 = getLayerByName(link_layer_1_name)
link_layer_2 = getLayerByName(link_layer_2_name)

import networkx as nx
from networkx import connected_components

edges = []
l1s = {}
l2s = {}
for i in link_layer_1.getFeatures():
    edges.append(({'l1':i.attributes()[1]}, {'l2',i.attributes()[2])})
for i in link_layer_2.getFeatures():
    edges.append(({'l2':i.attributes()[1]}, {'l1':i.attributes()[2]}))


for i in layer_1.getFeatures():
    l1s[i.attributes()[0]] = {'centroid': i.geometry().centroid(),
							'choice800': i.attributes()['T1024_Choice_R800_metric'],
							'choice1200': i.attributes()['T1024_Choice_R1200_metric'],
							'choice2000': i.attributes()['T1024_Choice_R2000_metric'],
							'choice3200': i.attributes()['T1024_Choice_R3200_metric'],
							'choice5000': i.attributes()['T1024_Choice_R5000_metric'],
							'choicen': i.attributes()['T1024_Choice'],
							'td800': i.attributes()['T1024_Total_Depth_R800_metric'],
							'td1200': i.attributes()['T1024_Total_Depth_R1200_metric'],
							'td2000': i.attributes()['T1024_Total_Depth_R2000_metric'],
							'td3200': i.attributes()['T1024_Total_Depth_R3200_metric'],
							'td5000': i.attributes()['T1024_Total_Depth_R5000_metric'],
							'tdn': i.attributes()['T1024_Total_Depth']
							}
for i in layer_2.getFeatures():
    l1s[i.attributes()[0]] = {'centroid': i.geometry().centroid(),
							'choice800': i.attributes()['T1024_Choice_R800_metric'],
							'choice1200': i.attributes()['T1024_Choice_R1200_metric'],
							'choice2000': i.attributes()['T1024_Choice_R2000_metric'],
							'choice3200': i.attributes()['T1024_Choice_R3200_metric'],
							'choice5000': i.attributes()['T1024_Choice_R5000_metric'],
							'choicen': i.attributes()['T1024_Choice'],
							'td800': i.attributes()['T1024_Total_Depth_R800_metric'],
							'td1200': i.attributes()['T1024_Total_Depth_R1200_metric'],
							'td2000': i.attributes()['T1024_Total_Depth_R2000_metric'],
							'td3200': i.attributes()['T1024_Total_Depth_R3200_metric'],
							'td5000': i.attributes()['T1024_Total_Depth_R5000_metric'],
							'tdn': i.attributes()['T1024_Total_Depth']
							}

g = nx.MultiGraph()
g.add_edges_from(edges)

new_fields = [QgsField('group_id',QVariant.Int), QgsField('type',QVariant.String), QgsField('id',QVariant.Int)]
if path is None:
    mm_rel = QgsVectorLayer('LineString?crs=' + crs.toWkt(), link_layer_name, "memory")
else:
    fields = QgsFields()
    for field in new_fields:
        fields.append(field)
    file_writer = QgsVectorFileWriter(path, encoding, fields, geom_type, crs, "ESRI Shapefile")
    if file_writer.hasError() != QgsVectorFileWriter.NoError:
        print "Error when creating shapefile: ", file_writer.errorMessage()
    del file_writer
    mm_rel = QgsVectorLayer(path, link_layer_name, "ogr")
    pr = mm_rel.dataProvider()
    if path is None:
        pr.addAttributes(layer_fields)

comp_key = 0
f = csv.writer(open(path_csv, "wb+"))
col_names = ['ids_1', 'ids_2', 'choice800_agg1', 'choice800_agg2', 'choice1200_agg1', 'choice1200_agg2', 'choice2000_agg1', 'choice2000_agg2', 'choice3200_agg1', 'choice3200_agg2', 'choice5000_agg1', 'choice5000_agg2', 'choicen_agg1', 'choicen_agg2' /
				             , 'td800_agg1', 'td800_agg2', 'td1200_agg1', 'td1200_agg2', 'td2000_agg1', 'td2000_agg2', 'td3200_agg1', 'td3200_agg2', 'td5000_agg1', 'td5000_agg2', 'tden_agg1', 'tdn_agg2']
f.writerow(col_names)
for i in g.connected_components():
    comp_key += 1
    all_centroids = []
    agg_l1_ids = []
    agg_l2_ids = []
    if i.keys()[0] is 'l1':
        all_centroids.append(l1s['centroid'])
        agg_l1_ids.append(i.keys()[0])
    elif i.keys()[0] is 'l2':
        all_centroids.append(l2s['centroid'])
        agg_l2_ids.append(i.keys()[0])
    line_feat = []
    centroid_of_centroids =
    for i in all_centroids:
        new_feat = QgsFeature()
        attr = [comp_key, i.keys()[0], i.values()[0]]
        geom = QgsGeometry.fromPolyline(i, centroid_of_centroids)
        new_feat.setAttributes(attr)
        new_feat.setGeometry(geom)
        line_feat.append(new_feat)
    mm_rel.startEditing()
    pr.addFeatures(new_features)
    mm_rel.commitChanges()
	choice800_agg1 = 0
	choice1200_agg1 = 0
	choice2000_agg1 = 0
	choice3200_agg1 = 0
	choice5000_agg1 = 0
	choicen_agg1 = 0
	td800_agg1 = 0
	td1200_agg1 = 0
	td2000_agg1 = 0
	td3200_agg1 = 0
	td5000_agg1 = 0
	tdn_agg1 = 0

	choice800_agg2 = 0
	choice1200_agg2 = 0
	choice2000_agg2 = 0
	choice3200_agg2 = 0
	choice5000_agg2 = 0
	choicen_agg2 =	0
	td800_agg2 = 0
	td1200_agg2	= 0
	td2000_agg2	= 0
	td3200_agg2	= 0
	td5000_agg2	= 0
	tdn_agg2 = 0
	for i in agg_l1_ids:
		choice800_agg1 += l1s['choice800']
		choice1200_agg1 +=l1s['choice1200']
		choice2000_agg1 += l1s['choice2000']
		choice3200_agg1 += l1s['choice3200']
		choice5000_agg1 += l1s['choice5000']
		choicen_agg1 += l1s['choicen']
		td800_agg1 += l1s['td800']
		td1200_agg1 += l1s['td1200']
		td2000_agg1 += l1s['td2000']
		td3200_agg1 += l1s['td3200']
		td5000_agg1 += l1s['td5000']
		tdn_agg1 += l1s['tdn']
	for i in agg_l2_ids:
		choice800_agg2 += l2s['choice800']
		choice1200_agg2 += l2s['choice1200']
		choice2000_agg2 +=l2s['choice2000']
		choice3200_agg2 += l2s['choice3200']
		choice5000_agg2 +=l2s['choice5000']
		choicen_agg2 +=	l2s['choicen']
		td800_agg2 +=	l2s['td800']
		td1200_agg2	+= l2s['td1200']
		td2000_agg2	+=l2s['td2000']
		td3200_agg2	+=l2s['td3200']
		td5000_agg2	+=l2s['td5000']
		tdn_agg2 +=l2s['tdn']
	f.writerow([agg_l1_ids, agg_l2_ids,choice800_agg1, choice800_agg2,choice1200_agg1,choice1200_agg2,choice2000_agg1,choice2000_agg2,choice3200_agg1, choice3200_agg2,choice5000_agg1,choice5000_agg2,choicen_agg1,choicen_agg2,/
	td800_agg1,td800_agg2,td1200_agg1,td1200_agg2,td2000_agg1,td2000_agg2,td3200_agg1,td3200_agg2,td5000_agg1,td5000_agg2,tden_agg1,tdn_agg2]
