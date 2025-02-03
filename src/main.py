import os
from util.general import Sentinel2Reader, load_dem_utm, PcdGenerator

# Get the HDB token from environment variables
token = os.environ.get('hdb_token')

# Define the file path for Sentinel-2 product
product_path = "/home/ubuntu/project/destine-godot-mvp/src/sentinel2-data/T32TLR_20241030T103151_TCI_20m.jp2"

# Initialize Sentinel2Reader with the product file
reader = Sentinel2Reader(filepath=product_path, preprocess=True)

# Get bounds and dimensions of the Sentinel-2 product
bounds = reader.bounds
width = reader.width
height = reader.height

parameter = 'dem'
dem_data = load_dem_utm(token, parameter, bounds, width, height)

# Initialize the PcdGenerator to generate point cloud
pcd_gen = PcdGenerator(reader.data, dem_data, sample_fraction=20)

# Generate point cloud data
pcd_gen.generate_point_cloud()

# Convert to Open3D point cloud object
pcd = pcd_gen.to_open3d()

# Save the generated point cloud to a PLY file
pcd_gen.save_point_cloud("model.ply")
