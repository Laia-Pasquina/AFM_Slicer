/*
 * A program to take a square AFM image, change it to greyscale, scale the image down and filter it.
 * 
 * Authors: Dr Laia Pasquina-Lemonche & Matthew Barker, University of Sheffield, UK, 
 * 			
 * Date: Original- May 2020, Update- Dec 2023
 * 
 */
 
 run("Close All");
print("\\Clear");

print("  ");
print("Select image to be processed");
print("  ");
open();

//Ask user if greyscale is required
GREY = getBoolean("Is greyscale REQUIRED?");

//Scale the image down to 520x520
run("Scale...", "x=- y=- width=520 height=520 interpolation=Bilinear average create");

//If needed, convert to greyscale
if(GREY == true) {
	//Split channels into RGB
	run("Split Channels");
	
	//find the titles of all images, and then close green and blue
	titles = newArray(nImages());
	
	for(i=1; i<=nImages(); i++) {
		//Get the titles from the images
		selectImage(i);
		titles[i-1] = getTitle();
		NaM = titles[i-1];
		
		//Find Blue channel and close it
		A = endsWith(NaM, "blue)");
		if(A == 0) {
			run("Close");
		}
		
		//Find green channel and close it
		B = endsWith(NaM, "green)");
		if(B == "0") {
			run("Close");
		}
	}
}

//Filter image
run("Despeckle");
run("Remove Outliers...", "radius=10 threshold=50 which=Bright");
run("Median...", "radius=2");

//Select final image and get title, renaming with Filtered_name
//selectImage(2);

print("  ");
print("What name would you like the filtered image to be given with type (file.type)");
print("  ");
name2 = getString("File name.type", "name.tif");

print("  ");
print("Select the folder to save the image in");
print("  ");
dir2 = getDirectory("Choose a Directory");

saveAs("tiff", dir2+name2);

print("\\Clear");
print("Filter code has finished");

run("Close All");