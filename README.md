# destine-godot-mvp


LiDAR HD IGN data:
https://diffusion-lidarhd.ign.fr/

To upload and visualize LiDAR data in Godot, especially in the .copc.laz format, we have to process the file into a format that Godot can work with. Godot does not natively support .copc.laz files, so we have to convert and preprocess the data.


```bash

sudo apt install -y g++ cmake libboost-all-dev libjsoncpp-dev libxml2-dev libgdal-dev
```



