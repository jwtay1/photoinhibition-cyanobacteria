# Photodamage in Cyanobacteria

This repository contains image and data analysis code for the photodamage 
project.

## Features

* Import data of tracked cells from CyAn
* Automatic identification of cell type (WT or $\delta$cpc)
* Identification of cell fate (alive or dead)
* Data analysis

## Installation and Usage

The PhotodamageAnalyzer object is a subclass of TrackArray. Hence, it 
requires the Linear Assignment Toolbox.

For more details, consult the Wiki

### Importing tracked data

1. Create a new `PhotodamageAnalyzer` object
   
   ```matlab
   P = PhotodamageAnalyzer
   ```
   
2. Import data (don't specify a file path to open a dialog box)
   
   ```matlab
   P = importdata(P, 'path/to/data.mat');
   ```

