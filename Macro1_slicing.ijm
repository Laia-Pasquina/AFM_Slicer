
/*
 * Macro1_Slicing: Converts an AFM image into a stack of binary images and exports the stack in .tiff or .obj format
 * 
 * Authors: Dr Laia Pasquina-Lemonche & Matthew Barker, University of Sheffield, UK, 
 * 			
 * Date of Original: 12th May 2020
 * 
 * LATEST UPDATE: Automated batch processing to cycle through a full folder of stacks 
 * Date: 25th November 2024
 */

run("Close All");
print("\\Clear");

//Select folder of images to be processed, retrieve file names and create new folder for the stacks to be saved in
print("Select folder containing images to be processed");
dir1 = getDirectory("Select the folder containing images");
list = getFileList(dir1);
dir2 = dir1 + File.getName(dir1) + "_Stacks" + File.separator;
File.makeDirectory(dir2);

//Give the number of slices to cut the image into
number_slices = getNumber("Number of slices to make from the image (max 255)", 255);

//Choose whether filled area will represent pores or surface
represent = getBoolean("Represent Pores or Surface? (Pores required for Code 2)", "Pores", "Surface");

//Ask user if greyscale is required and whether to save filtered image
GREY = getBoolean("Is your image already in Greyscale colour?");

//Uncomment this line below ("33") and comment line ("34) if you want to ask user about filtered image.
//SaveFiltered = getBoolean("Do you want to save the filtered image as well?");
SaveFiltered = false; //The default is to not save this.

print("\\Clear");
print("Slicing Underway");

for (j=0; j<list.length; j++) {
	
	//Open image from the list
	open(dir1 + list[j]);

	//File name in form image.tif
	name0 = File.name;
	//File name in form image_filtered
	name1 = File.nameWithoutExtension +"_filtered";
	//File name in form image
	name2 = File.nameWithoutExtension;
	//File name in form image_
	name3 = File.nameWithoutExtension + "_";
	
	//Scale the image down to 520x520
	run("Scale...", "x=- y=- width=520 height=520 interpolation=Bilinear average create");
	
	//If needed, convert to greyscale
	if(GREY == false) {
		
		//Converts the image to greyscale without missing any data points
		run("8-bit");
		run("Grays");
	}
	
	//Filter image
	run("Despeckle");
	run("Remove Outliers...", "radius=10 threshold=50 which=Bright");
	run("Median...", "radius=2");
	
	saveAs("tiff", dir1+name1);
	
	run("Close All");
	
	//Reduces visual outputs
	setBatchMode(true);
	
	for(i = 0; i < number_slices; i++) {
		//Open greyscale image
		open(dir1 + name1 + ".tif");
		
		//Convert to 8-bit
		run("8-bit");
		
		//Threshold image
		setAutoThreshold("Otsu");
		
		a = 0;
		b = number_slices - i;
		
		setThreshold(a, b);
		
		//Apply the threshold. Selecting false makes holes black, true makes them white
		
		if (represent == 1) {
			setOption("BlackBackground", true);
			run("Convert to Mask");
		}
		if (represent == 0) {
			setOption("BlackBackground", false);
			run("Convert to Mask");
		}
	
	}
	
	//Stack images
	name4 = name2+"_AFMtomography_stack";
	run("Images to Stack", "title=[] use");
	rename(name4);
	saveAs("Tiff", dir1+name4);
	
	//Save the stack as Image Sequence for further analysis. Saves in a folder named Filename_stack in stacks folder
	savepoint = dir2 + name2 + "_stack" + File.separator;
	File.makeDirectory(savepoint);
	run("Image Sequence... ", "format=TIFF name="+name3+" digits=3 save=["+savepoint+"]");
	
	//If requested, remove filtered image
	if (SaveFiltered == false) {
		File.delete(dir1+name1+".tif")
	}
	
	/*
	 //This does not work, this is to download file in .obj
	//Ask user if they also want to export the image in .obje (recommended for ChimeraX and needed for Blender
	OBJ = getBoolean("Do you want to also save image in .OBJ format? (recommeded for ChimeraX, needed for Blender)");
	
	if(OBJ == true){
		selectImage(name4+".tif");
		rename(name4);
		run("Wavefront .OBJ ...", "stack="+name4+" threshold=0 resampling=2 red green blue save="+dir1+"3D_image");
	}*/
	
	

}

print("\\Clear");
print("Stacking complete");