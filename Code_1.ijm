/*
 * AFMSlicer - Program to slice the AFM images into several 2D binary slices.
 * 
 * Authors: Dr Laia Pasquina-Lemonche & Matthew Barker, University of Sheffield, UK, 
 * 			
 * Date: Original- May 2020, Update- Dec 2023
 */
run("Close All");
print("\\Clear");

//Open the image to be processed, obtain location information and then close the image
print("  ");
print("Select image to be processed");
print("  ");
open();
dir1 = File.directory;
name1 = File.name;
name2 = File.nameWithoutExtension + "_";
run("Close All");


//Give the number of slices to cut the image into
number_slices = getNumber("Number of slices to make from the image (max 255)", 255);

//Reduces visual outputs
setBatchMode(true);

print("\\Clear");
print("  ");
print("Beginning slicing");
print("  ");

for(i = 0; i < number_slices; i++) {
	//Open greyscale image
	open(dir1 + name1);
	
	//Convert to 8-bit
	run("8-bit");
	
	//Threshold image
	setAutoThreshold("Otsu");
	
	a = 0;
	b = number_slices - i;
	
	setThreshold(a, b);
	
	//Apply the threshold. Selecting false makes holes black, true makes them white
	
	setOption("BlackBackground", true);
	run("Convert to Mask");
	
	//Clean up the binary image
	//run("Fill Holes");
	//run("Open");
}

print("\\Clear");
print("  ");
print("Slicing complete. Beginning stacking");

//Stack images
run("Images to Stack", "name=Stack2 title=[] use");

//Name the stack without file type
//print("\\Clear");
//print("  ");
//print("Write the name of the stack, followed by an underscore (_)");
//print("  ");

//name2 = getString("File name", "Image1_");

//Save stack as tiff and gif
//saveAs("tiff", dir1 + name2);
//saveAs("gif", dir1 + name2);

//Save the stack as Image Sequence for further analysis. Saves in a folder named Filename_stack in selected directory
print("\\Clear");
print("  ");
print("Choose location for stack folder to be saved");
print("  ");
dir2 = getDirectory("Choose a Directory");
savepoint = dir2 + name2 + "stack" + File.separator;
File.makeDirectory(savepoint);
run("Image Sequence... ", "format=TIFF name="+name2+" digits=3 save=["+savepoint+"]");

print("\\Clear");
print("Stacking complete");