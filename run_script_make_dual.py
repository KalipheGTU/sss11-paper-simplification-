# cleaning settings
layer_name = 'osm_dp20_inter10'
path = None
tolerance =6
user_id ='Gid'
# project settings
layer = getLayerByName(layer_name)
crs = layer.dataProvider().crs()
encoding = layer.dataProvider().encoding()
geom_type = layer.dataProvider().geometryType()

# if unique id is specified use it as keys
# else create new
# check uid before

aR=sGraph(layer, tolerance, user_id, True)
aR.prepare()
aR.make_dual_edges()
aR.to_dual_shp(None, crs, 'osm_dp20_inter10_dual', encoding, geom_type)
QgsMapLayerRegistry.instance().addMapLayer(aR.dual_network)

threshold = 5

fields = aR.layer_fields
simplified_features = aR.simplifyShortLines(5)
final = to_shp(None, simplified_features, fields, crs, 'osm_simpl10_5', encoding, geom_type)
QgsMapLayerRegistry.instance().addMapLayer(final)

short_network = to_short_shp(None, aR._short_edges, crs, 'osm_simpl10_5_short', encoding, geom_type)
QgsMapLayerRegistry.instance().addMapLayer(short_network)
