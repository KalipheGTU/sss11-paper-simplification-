

# imports
from qgis.core import QgsFeature, QgsGeometry, QgsSpatialIndex, QgsPoint, QgsVectorFileWriter, QgsField
from PyQt4.QtCore import QObject, pyqtSignal, QVariant
import itertools
import math

# dual graph
# constuct edges
# make features

def getLayerByName(name):
	layer = None
	for i in QgsMapLayerRegistry.instance().mapLayers().values():
		if i.name() == name:
			layer = i
	return layer

def make_snapped_wkt(wkt, number_decimals):
	# TODO: check in different system if '(' is included
	snapped_wkt = 'LINESTRING('
	for i in vertices_from_wkt_2(wkt):
		new_vertex = str(keep_decimals_string(i[0], number_decimals)) + ' ' + str(
			keep_decimals_string(i[1], number_decimals))
		snapped_wkt += str(new_vertex) + ', '
	return snapped_wkt[0:-2] + ')'

def vertices_from_wkt_2(wkt):
	# the wkt representation may differ in other systems/ QGIS versions
	# TODO: check
	nums = [i for x in wkt[11:-1:].split(', ') for i in x.split(' ')]
	if wkt[0:12] == u'LineString (':
		nums = [i for x in wkt[12:-1:].split(', ') for i in x.split(' ')]
	coords = zip(*[iter(nums)] * 2)
	for vertex in coords:
		yield vertex

def keep_decimals_string(string, number_decimals):
	integer_part = string.split(".")[0]
	# if the input is an integer there is no decimal part
	if len(string.split("."))== 1:
		decimal_part = str(0)*number_decimals
	else:
		decimal_part = string.split(".")[1][0:number_decimals]
	if len(decimal_part) < number_decimals:
		zeros = str(0) * int((number_decimals - len(decimal_part)))
		decimal_part = decimal_part + zeros
	decimal = integer_part + '.' + decimal_part
	return decimal


class sGraph(QObject):

	finished = pyqtSignal(object)
	error = pyqtSignal(Exception, basestring)
	progress = pyqtSignal(float)
	warning = pyqtSignal(str)

	def __init__(self,layer, tolerance, uid, errors):
		QObject.__init__(self)
		self.layer = layer
		self.tolerance = tolerance
		self.uid = uid
		self.errors = errors

		# quick ones
		self.feat_count = self.layer.featureCount()
		self.layer_fields = [QgsField(i.name(), i.type()) for i in self.layer.dataProvider().fields()]
		if self.uid is not None:
			self.uid_index = [index for index,field in enumerate(self.layer_fields) if field.name() == self.uid].pop()

		# to prepare
		self.multiparts = []
		self.points = []
		self.invalids = []
		self.features = []
		self.attributes = {}
		self.geometries = {}
		self.geometries_wkt = {}
		self.geometries_vertices = {}
		# create spatial index object
		self.spIndex = QgsSpatialIndex()
		self.fid_to_uid = {}
		self.uid_to_fid = {}

		# to make dual

		self.all_con = {}
		self.vertices_occur = {}
		self.edges_occur = {}
		self.f_dict = {}
		self.self_loops = []

	def prepare(self):

		new_key_count = 0
		f_count = 1
		for f in self.layer.getFeatures():

			self.progress.emit(45 * f_count / self.feat_count)
			f_count += 1

			attr = f.attributes()
			if f.geometry().wkbType() == 5 :
				attr = f.attributes()
				if self.errors and self.uid is not None:
					self.multiparts.append(attr[self.uid_index])
					self.uid_to_fid[attr[self.uid_index]] = f.id()
				for multipart in f.geometry().asGeometryCollection():
					if self.uid is not None:
						self.fid_to_uid[f.id()] = attr[self.uid_index]
					new_key_count += 1
					new_feat = QgsFeature()
					new_feat.setAttributes(attr)
					snapped_wkt = make_snapped_wkt(multipart.exportToWkt(), self.tolerance)
					self.features.append([new_key_count, f.attributes(), snapped_wkt])
					self.attributes[f.id()] = attr
					self.geometries[f.id()] = QgsGeometry.fromWkt(snapped_wkt)
					self.geometries_wkt[f.id()] = snapped_wkt
					self.geometries_vertices[f.id()] = [vertex for vertex in vertices_from_wkt_2(snapped_wkt)]
					# insert features to index
					# self.spIndex.insertFeature(f)
			elif f.geometry().wkbType() == 1:
				if self.errors and self.uid is not None:
					self.points.append(attr[self.uid_index])
			elif not f.geometry().isGeosValid():
				if self.errors and self.uid is not None:
					self.invalids.append(attr[self.uid_index])
			elif f.geometry().wkbType() == 2:
				new_key_count += 1
				new_feat = QgsFeature()
				new_feat.setAttributes(attr)
				snapped_wkt = make_snapped_wkt(f.geometry().exportToWkt(), self.tolerance)
				self.features.append([new_key_count, f.attributes(), snapped_wkt])
				self.attributes[f.id()] = attr
				self.geometries[f.id()] = QgsGeometry.fromWkt(snapped_wkt)
				self.geometries_wkt[f.id()] = snapped_wkt
				self.geometries_vertices[f.id()] = [vertex for vertex in vertices_from_wkt_2(snapped_wkt)]
				# insert features to index
				self.spIndex.insertFeature(f)
				if self.uid is not None:
					self.fid_to_uid[f.id()] = attr[self.uid_index]
					self.uid_to_fid[attr[self.uid_index]] = f.id()
		return

	def make_dual_edges(self):

		for i in self.features:
			self.f_dict[i[0]] = [i[1], i[2]]
			for vertex in vertices_from_wkt_2(i[2]):
				break
			first = vertex
			for vertex in vertices_from_wkt_2(i[2]):
				pass
			last = vertex
			try:
				self.vertices_occur[first] += [i[0]]
			except KeyError, e:
				self.vertices_occur[first] = [i[0]]
			try:
				self.vertices_occur[last] += [i[0]]
			except KeyError, e:
				self.vertices_occur[last] = [i[0]]
			pair = (last, first)
			# strings are compared
			if first[0] > last[0]:
				pair = (first, last)
			try:
				self.edges_occur[pair] += [i[0]]
			except KeyError, e:
				self.edges_occur[pair] = [i[0]]

		self.all_con = {}
		self.dual_edges = {}
		for k, v in self.vertices_occur.items():
			for x in itertools.combinations(v,2):
				if x[0]< x[1]:
					geom0 = QgsGeometry.fromWkt(self.f_dict[x[0]][1])
					geom1 = QgsGeometry.fromWkt(self.f_dict[x[1]][1])
					angle = get_3_points(geom0, geom1)
					self.dual_edges[x]= {'angle': 180-angle}
		return

	def to_dual_shp(self,path, crs, name, encoding, geom_type):
		midpoints = { i[0]: pl_midpoint(QgsGeometry.fromWkt(i[2])) for i in self.features}
		layer_fields = [QgsField('id', QVariant.Int), QgsField('source', QVariant.String), QgsField('target', QVariant.String), QgsField('angle', QVariant.Int)]
		if path is None:
			self.dual_network = QgsVectorLayer('LineString?crs=' + crs.toWkt(), name, "memory")
		else:
			fields = QgsFields()
			for field in layer_fields:
				fields.append(field)
			file_writer = QgsVectorFileWriter(path, encoding, fields, geom_type, crs, "ESRI Shapefile")
			if file_writer.hasError() != QgsVectorFileWriter.NoError:
				print "Error when creating shapefile: ", file_writer.errorMessage()
			del file_writer
			self.dual_network = QgsVectorLayer(path, name, "ogr")
		pr = self.dual_network.dataProvider()
		if path is None:
			pr.addAttributes(layer_fields)
		new_features = []
		count = 1
		for k,v in self.dual_edges.items():
			new_feat = QgsFeature()
			new_feat.setFeatureId(count)
			new_feat.setAttributes([count, str(k[0]), str(k[1]),v['angle']])
			count += 1
			midpoint0 = midpoints[k[0]]
			midpoint1 = midpoints[k[1]]
			new_feat.setGeometry( QgsGeometry.fromPolyline([QgsPoint(midpoint0[0],midpoint0[1]), QgsPoint(midpoint1[0],midpoint1[1])]))
			new_features.append(new_feat)
		self.dual_network.startEditing()
		pr.addFeatures(new_features)
		self.dual_network.commitChanges()
		return

	def simplifyShortLines(self, threshold):

		aR.vertices_occur = {}
		short = []
		# short_edges = []
		for i in aR.features:
			aR.f_dict[i[0]] = [i[1], i[2]]
			for vertex in vertices_from_wkt_2(i[2]):
				break
			first = vertex
			for vertex in vertices_from_wkt_2(i[2]):
				pass
			last = vertex
			if QgsGeometry.fromWkt(i[2]).length() < threshold:
				short.append(i[0])
			try:
				aR.vertices_occur[first] += [i[0]]
			except KeyError, e:
				aR.vertices_occur[first] = [i[0]]
			try:
				aR.vertices_occur[last] += [i[0]]
			except KeyError, e:
				aR.vertices_occur[last] = [i[0]]

		spIndex = QgsSpatialIndex()
		inter_dict = {}
		count = 1
		for vertex, edges in aR.vertices_occur.items():
			feature = QgsFeature()
			feature.setGeometry(QgsGeometry.fromPoint(QgsPoint(float(vertex[0]),float(vertex[1]))))
			feature.setAttributes([count])
			feature.setFeatureId(count)
			inter_dict[count] = vertex
			count += 1
			spIndex.insertFeature(feature)

		self._short_edges = []
		for vertex, edges in aR.vertices_occur.items():
			inter_points = spIndex.intersects(QgsGeometry.fromPoint(QgsPoint(float(vertex[0]),float(vertex[1]))).buffer(threshold,10).boundingBox())
			pot_points = [inter_dict[i] for i in inter_points if i not in aR.vertices_occur[vertex] and vertex != inter_dict[i]]
			for point in pot_points:
				if point[0] < vertex[0]:
					if math.hypot(abs(float(point[0]) - float(vertex[0])),abs(float(point[1])- float(vertex[1]))) < threshold:
						self._short_edges.append((point,vertex))

		import networkx as nx
		from networkx import connected_components
		nxgraph = nx.MultiGraph()
		nxgraph.add_edges_from(self._short_edges)

		collapsed = []

		for group in connected_components(nxgraph):
			neighbours = []
			for item in group:
				neighbours += aR.vertices_occur[item]
			neigh_filt = [i for i in list(set(neighbours)) if i not in short]
			neigh_lengths = [ QgsGeometry.fromWkt(aR.f_dict[i][1]).length() for i in neigh_filt]
			if len(neigh_filt)>0:
				longest_l = neigh_filt[neigh_lengths.index(max(neigh_lengths))]
				for vertex in vertices_from_wkt_2(aR.f_dict[longest_l][1]):
					break
				first = vertex
				for vertex in vertices_from_wkt_2(aR.f_dict[longest_l][1]):
					pass
				last = vertex
				longest_p = first
				if last in group:
					longest_p = last
				for i in neigh_filt:
					attr = aR.f_dict[i][0]
					last_index = -1
					vertex_index = 0
					for vertex in vertices_from_wkt_2(aR.f_dict[i][1]):
						last_index += 1
					l_v = vertex
					for vertex in vertices_from_wkt_2(aR.f_dict[i][1]):
						break
					l_f = vertex
					if l_v in group and not l_f in group:
						vertex_index = last_index
					if not (l_f in group and l_v in group):
						new_wkt = 'LINESTRING('
						for index, v in enumerate(vertices_from_wkt_2(aR.f_dict[i][1])):
							new_vertex = str(v[0]) + ' ' + str(v[1])
							if index == vertex_index:
								new_vertex = 	str(longest_p[0]) + ' ' + str(longest_p[1])
							new_wkt += new_vertex + ', '
						new_wkt = new_wkt[0:-2] + ')'
						if QgsGeometry.fromWkt(new_wkt).length() > 0.000000001:
							aR.f_dict[i] = [attr, new_wkt]
					else:
						collapsed.append(i)

		simplified_features = []
		for k,v in aR.f_dict.items():
			if k not in short and k not in collapsed:
				simplified_features.append((k, v[0], v[1]))
		return simplified_features


def to_shp(path, any_features_list, layer_fields, crs, name, encoding, geom_type):
    if path is None:
        network = QgsVectorLayer('LineString?crs=' + crs.toWkt(), name, "memory")
    else:
        fields = QgsFields()
        for field in layer_fields:
            fields.append(field)
        file_writer = QgsVectorFileWriter(path, encoding, fields, geom_type, crs, "ESRI Shapefile")
        if file_writer.hasError() != QgsVectorFileWriter.NoError:
            print "Error when creating shapefile: ", file_writer.errorMessage()
        del file_writer
        network = QgsVectorLayer(path, name, "ogr")
    pr = network.dataProvider()
    if path is None:
        pr.addAttributes(layer_fields)
    new_features = []
    for i in any_features_list:
        new_feat = QgsFeature()
        new_feat.setFeatureId(i[0])
        new_feat.setAttributes(i[1])
        new_feat.setGeometry(QgsGeometry.fromWkt(i[2]))
        new_features.append(new_feat)
    network.startEditing()
    pr.addFeatures(new_features)
    network.commitChanges()
    return network

def to_short_shp(path, _short_edges, crs, name, encoding, geom_type):
	name = 'a'
	layer_fields = [QgsField('id', QVariant.Int), QgsField('source', QVariant.String), QgsField('target', QVariant.String)]
	if path is None:
		short_network = QgsVectorLayer('LineString?crs=' + crs.toWkt(), name, "memory")
	else:
		fields = QgsFields()
		for field in layer_fields:
			fields.append(field)
		file_writer = QgsVectorFileWriter(path, encoding, fields, geom_type, crs, "ESRI Shapefile")
		if file_writer.hasError() != QgsVectorFileWriter.NoError:
			print "Error when creating shapefile: ", file_writer.errorMessage()
		del file_writer
		short_network = QgsVectorLayer(path, name, "ogr")
	pr = short_network.dataProvider()
	if path is None:
		pr.addAttributes(layer_fields)
	new_features = []
	count = 1
	for i in _short_edges:
		new_feat = QgsFeature()
		new_feat.setFeatureId(count)
		new_feat.setAttributes([count, str(i[0]), str(i[1])])
		count += 1
		new_feat.setGeometry( QgsGeometry.fromPolyline([QgsPoint(float(i[0][0]),float(i[0][1])), QgsPoint(float(i[1][0]),float(i[1][1]))]))
		new_features.append(new_feat)
	short_network.startEditing()
	pr.addFeatures(new_features)
	short_network.commitChanges()
	return short_network

def get_3_points(geom0,geom1,polylines=False):
	inter_point = geom0.intersection(geom1)
	if polylines:
		vertex1 = geom0.asPolyline()[-2]
		if inter_point.asPoint() == geom0.asPolyline()[0]:
			vertex1 = geom0.asPolyline()[1]
		vertex2 = geom1.asPolyline()[-2]
		if inter_point.asPoint() == geom1.asPolyline()[0]:
			vertex2 = geom1.asPolyline()[1]
	else:
		vertex1 = geom0.asPolyline()[0]
		if inter_point.asPoint() == geom0.asPolyline()[0]:
			vertex1 = geom0.asPolyline()[-1]
		vertex2 = geom1.asPolyline()[0]
		if inter_point.asPoint() == geom1.asPolyline()[0]:
			vertex2 = geom1.asPolyline()[-1]
	angle = angle_3_points(inter_point, vertex1, vertex2)
	return angle

def mid(pt1, pt2):
	x = (pt1.x() + pt2.x()) / 2
	y = (pt1.y() + pt2.y()) / 2
	return (x, y)

def angle_3_points(inter_point, vertex1, vertex2):
	inter_vertex1 = math.hypot(abs(inter_point.asPoint()[0] - vertex1[0]),
							   abs(inter_point.asPoint()[1] - vertex1[1]))
	inter_vertex2 = math.hypot(abs(inter_point.asPoint()[0] - vertex2[0]),
							   abs(inter_point.asPoint()[1] - vertex2[1]))
	vertex1_2 = math.hypot(abs(vertex1[0] - vertex2[0]), abs(vertex1[1] - vertex2[1]))
	A = ((inter_vertex1 ** 2) + (inter_vertex2 ** 2) - (vertex1_2 ** 2))
	B = (2 * inter_vertex1 * inter_vertex2)
	if B != 0:
		cos_angle = A / B
	else:
		cos_angle = NULL
	if cos_angle < -1:
		cos_angle = int(-1)
	if cos_angle > 1:
		cos_angle = int(1)
	return math.degrees(math.acos(cos_angle))

def pl_midpoint(pl_geom):
	vertices = pl_geom.asPolyline()
	length = 0
	mid_length = pl_geom.length() / 2
	for ind, vertex in enumerate(vertices):
		start_vertex = vertices[ind]
		end_vertex = vertices[(ind + 1) % len(vertices)]
		length += math.hypot(abs(start_vertex[0] - end_vertex[0]), abs(start_vertex[1] - end_vertex[1]))
		ind_mid_before = ind
		ind_mid_after = ind + 1
		if length > mid_length:
			midpoint = mid(vertices[ind_mid_before], vertices[ind_mid_after])
			break
		elif length == mid_length:
			midpoint = vertices[ind_mid_after]
			break
		#    print vertices
		#    midpoint = vertices[ind_mid_after]
		#    break
	return midpoint
