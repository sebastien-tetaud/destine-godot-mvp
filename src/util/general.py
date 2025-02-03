import cv2 as cv
import matplotlib.pyplot as plt
import numpy as np
import rasterio
import xarray as xr


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