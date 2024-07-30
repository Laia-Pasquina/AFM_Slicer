# AFM_Slicer

**Location:** Department of physics and astronomy, University of Sheffield, UK. and School of Biosciences, University of Sheffield, UK.
**Updated:** July 2024 Dr Laia Pasquina Lemonche (https://github.com/Laia-Pasquina) and Matthew J Barker (https://github.com/Mjbarker2) (cc)

## Description of the program

The tipical representation of AFM images is a collection of points in a 3D matrix. 
However, they cannot be directly analysed in 3D because the current available software is
very limited and is designed to analyse features in 2D. Here, a collection of FIJI macros 
were made to slice and analyse AFM images into tomography-like stacks that can be read and 
interpreted by most 3D visualisation software like Blender or Imaris

**AFM Slicer part:**
FIJI macros (**code 0 and code 1**) 

These codes allow typical AFM images to be sliced into a stack of binary 2D slices. 
The resultant image can then be further analysed using Image J **code 2** macro presented here. 

**Pore Analysis part:**
FIJI macro (**code 2**) 

This code analyses properties of the pores in each of the 2D slice and then it outputs a list of 
values for each slice and a summary of the HCFA (Half cumulative fraction of Area) for the entire image.
These results were used to create the graphs of CFA vs Area in the Science publication.

## Steps to follow 

1. These are **FIJI macros**, so the first step is to **Download and Install FIJI**, [here][https://imagej.net/downloads].
2. The code is currenlty composed of code 0, code 1 and code 2. They should be run in order.
3. The imput file should be an AFM height image in .tif format extracted preferably from open-source software like Gwyddion or TopoStats, but other non-open source formats are accepted too. 
5. **IMPORTANT**  `The imput image should not have any scale bar, colour bar or any additional drawing, just the image without any edges` e.g. in Gwyddion you can do this by following this instructions: _File > Save as > File type (.TIFF) > Export Tiff window > Lateral scale (None) > Value scale (None) > Image draw frame (unticked)_
6. Open code 0 in FIJI and click **Run**, follow the instructions in the **Log windows**, first search for your .tif image.
7. Then repeat step 6 for code 1 and 2. You will be asked in code 2 to enter the dimensions **(XY distance in nm)** of your image. You can obtain this from any AFM visualisation software. e.g. in Gwyddion you can do this by following this instructions: _Open image in .spm format > Data Process > Basic operations > Dimensions and Units > Dimensions_ You will also be asked in code 1 and 2 to provide the amount of slices you desire to analyse. For an image to be completely split in the maximum amount of slices select 255 (which is the maximum number of slices it does because the code converts the image to 8 bit).
8. The results can be found in the Results folder. The output for each image is an Excel file containing the number of pores called **_Colour count_** and the pore area versus depth slice called **_Final_**

Follow **AFMSlicer tutorial video** for a detail step-by-step use of the three codes to analyse an image of AFM containing pores.
