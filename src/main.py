import sys
import os
from util.general import (Sentinel2Reader, load_dem_utm,
                     PcdGenerator, PointCloudHandler)

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
pcd_gen.downsample(sample_fraction=0.35)

handler = PointCloudHandler(pcd_gen.df)
handler.to_open3d()
handler.save_point_cloud(filename="model.ply")