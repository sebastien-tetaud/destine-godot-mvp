import sys
import os
import numpy as np
import open3d as o3d


from util.general import Sentinel2Reader, load_dem_utm, PcdGenerator, PointCloudHandler

token = os.environ.get('hdb_token')
product_path = "/home/ubuntu/project/destine-godot-mvp/src/sentinel2-data/T32TLR_20241030T103151_TCI_20m.jp2"
reader = Sentinel2Reader(filepath=product_path, preprocess=True)
bounds = reader.bounds
width = reader.width
height = reader.height
parameter = 'dem'
dem_data = load_dem_utm(token, parameter, bounds, width, height)
# Initialize and generate point cloud
pcd_gen = PcdGenerator(reader.data, dem_data)

pcd_gen.generate_point_cloud()
pcd_gen.downsample(sample_fraction=0.30)

handler = PointCloudHandler(pcd_gen.df)
handler.to_open3d()
handler.generate_mesh(depth=9)
handler.save_point_cloud("point_cloud.ply")
handler.save_mesh("mesh.glb")

