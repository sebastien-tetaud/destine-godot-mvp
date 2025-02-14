import cv2 as cv
import open3d as o3d
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import rasterio
import xarray as xr


def load_dem_utm(token, parameters,  bounds, width, height):
    """
    Loads the Copernicus DEM (GLO-30 UTM) and selects the region of interest.

    Parameters:
        token (str): Authentication token for accessing the dataset.
        parameters(str): Parameters.
        bounds (rasterio.coords.BoundingBox): Bounding box with left, right, bottom, top coordinates.
        width (int): Number of pixels (columns) in the target image.
        height (int): Number of pixels (rows) in the target image.

    Returns:
        xarray.DataArray: DEM region of interest.
    """
    # Define the dataset URL
    dem_url = f"https://edh:{token}@data.earthdatahub.destine.eu/copernicus-dem-utm/GLO-30-UTM-v0/32N"

    # Load the dataset
    dem = xr.open_dataset(dem_url, chunks={}, engine="zarr")

    # Create UTM coordinate grid
    x = np.linspace(bounds.left, bounds.right, width)
    y = np.linspace(bounds.bottom, bounds.top, height)

    # Select the DEM region of interest using nearest interpolation
    dem_roi = dem.sel(x=x, y=y, method="nearest")

    return dem_roi[parameters]


class Sentinel2Reader:
    """
    A class to read and preprocess Sentinel-2 satellite L2A.

    This class loads Sentinel-2 L2A product, extracts metadata, and provides
    functionalities for preprocessing (flipping and transposing) and visualization.

    Attributes:
        filepath (str): Path to the Sentinel-2 image file.
        data (numpy.ndarray or None): Image data after reading and preprocessing.
        bounds (rasterio.coords.BoundingBox or None): Bounding box of the image.
        transform (Affine or None): Affine transformation matrix of the image.
        height (int or None): Number of rows (pixels) in the image.
        width (int or None): Number of columns (pixels) in the image.
    """

    def __init__(self, filepath, preprocess=True):
        """
        Initializes the Sentinel2Reader instance and loads the image.

        Args:
            filepath (str): Path to the Sentinel-2 image file.
            preprocess (bool, optional): Whether to preprocess the image (default is True).
        """
        self.filepath = filepath
        self.data = None
        self.bounds = None
        self.transform = None
        self.height = None
        self.width = None

        self.read_image()
        if preprocess:
            self.preprocess()

    def read_image(self):
        """
        Reads the Sentinel-2 image and extracts metadata.

        This method loads the image using rasterio and extracts useful metadata such as
        image dimensions, bounds, and transformation matrix.
        """
        try:
            with rasterio.open(self.filepath) as src:
                self.data = src.read()
                self.bounds = src.bounds
                self.transform = src.transform
                self.height = src.height
                self.width = src.width
        except Exception as e:
            print(f"Error reading image: {e}")

    def preprocess(self):
        """
        Transposes and flips the image for correct visualization.

        Sentinel-2 images are stored as (Bands, Height, Width), so we transpose them
        to (Height, Width, Bands) for proper display. The image is then flipped
        vertically to match conventional visualization.
        """
        if self.data is not None:
            self.data = np.transpose(self.data, (1, 2, 0))  # Change dimensions
            self.data = cv.flip(self.data, 0)  # Flip vertically
        else:
            print("No image data to preprocess.")

    def show_image(self):
        """
        Displays the processed Sentinel-2 image.

        If the image is loaded and processed, it will be displayed using Matplotlib.
        Otherwise, an error message is printed.
        """
        if self.data is not None:
            plt.imshow(self.data)
            plt.axis("off")
            plt.show()
        else:
            print("No image data loaded.")


class PcdGenerator:
    def __init__(self, sat_data, dem_data, sample_fraction=20):
        """
        Initialize the PCD Generator.

        Args:
            sat_data (numpy.ndarray): Sentinel-2 RGB data with shape (H, W, 3).
            dem_data (xarray.DataArray): DEM data with coordinates.
            sample_fraction (int): Percentage of points to sample (default: 20%).
        """
        self.sat_data = sat_data
        self.dem_data = dem_data
        self.sample_fraction = sample_fraction
        self.point_cloud = None
        self.df = None  # Dataframe holding point cloud data

    def _normalize_rgb(self, rgb_array):
        """Normalize RGB values to range [0, 1]."""
        return np.array(rgb_array) / 255.0

    def generate_point_cloud(self):
        """Generate a point cloud from Sentinel-2 and DEM data."""
        # Extract lat/lon and DSM values
        lat_values = self.dem_data.coords['y'].values  # Latitude
        lon_values = self.dem_data.coords['x'].values  # Longitude
        dsm_values = self.dem_data.values  # Elevation

        # Reshape Sentinel-2 RGB data to (N, 3)
        tci_rgb = self.sat_data.reshape(-1, 3)
        rgb_tuples = [tuple(rgb) for rgb in tci_rgb]

        # Create a meshgrid for coordinates
        lon_grid, lat_grid = np.meshgrid(lon_values, lat_values)

        # Flatten everything to 1D
        lon_flat = lon_grid.flatten()
        lat_flat = lat_grid.flatten()
        dsm_flat = dsm_values.flatten()

        # Create a DataFrame to store point cloud data
        df = pd.DataFrame({
            'x': lon_flat,
            'y': lat_flat,
            'z': dsm_flat,
            'color': rgb_tuples
        })

        print(f"Total points before sampling: {len(df)}")

        # Apply sampling
        sample_size = int(self.sample_fraction * len(df) / 100)
        self.df = df[:sample_size]
        print(f"Sampled points: {len(self.df)}")

    def to_open3d(self):
        """Convert the DataFrame to an Open3D PointCloud object."""
        if self.df is None:
            raise ValueError("Point cloud data not generated. Run `generate_point_cloud()` first.")

        # Stack coordinates into a (N, 3) numpy array
        points = np.column_stack((self.df['x'], self.df['y'], self.df['z'].values))

        # Convert RGB colors to float values in range [0,1]
        colors = np.array(self.df['color'].apply(lambda x: np.array(x))) / 255.0

        # Create Open3D PointCloud object
        pcd = o3d.geometry.PointCloud()
        pcd.points = o3d.utility.Vector3dVector(points)
        pcd.colors = o3d.utility.Vector3dVector(colors)

        self.point_cloud = pcd
        return pcd

    def save_point_cloud(self, filename="point_cloud.ply"):
        """Save the generated point cloud to a file."""
        if self.point_cloud is None:
            self.to_open3d()

        o3d.io.write_point_cloud(filename, self.point_cloud)
        print(f"Point cloud saved to {filename}")

    def visualize(self):
        """Visualize the point cloud using Open3D."""
        if self.point_cloud is None:
            self.to_open3d()

        o3d.visualization.draw_geometries([self.point_cloud])