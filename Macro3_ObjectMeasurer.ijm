//Macro3_ObjectMeasurer from AFMSlicer - Code that is used to analyse AFM images that contain objects or features on a flat background
// (works best when objects are clearly separated from each other)
// Imputs: original AFM image in .tif format and greyscale // Stack of the material of the image from Code1_slicer
// Output: new stack with the background removed to be able to analyse only the objects // labelled image and coloured labelled image where colour = volume 
//         table with the parameters analysed (volume of objects, circularity, etc) - these can be changed by clicking on settings on the 3D ROI manager
// Resources and tutorials: GitHub page, 3D ROI Manager resources: https://imagejdocu.list.lu/tutorial/working/tutorial_for_3d_roi_manager
//--------
// Author: Dr Laia Pasquina Lemonche - V0.9 - 26 Feb 2025 University of Sheffield (c)
// Remaining to do: clean up code, do batch processing, annotate a bit more.


run("Close All");
print("\\Clear");
print("Select folder containing images in greyscale to be processed");

//This allows to run the program in batch processing
dir1 = getDirectory("Select the folder containing images");
list = getFileList(dir1);
dir2 = dir1 + File.getName(dir1) + "_Stacks" + File.separator;
File.makeDirectory(dir2);
dir3 = dir1 + File.getName(dir1) + "_Results" + File.separator;
File.makeDirectory(dir3);

//Select .txt file of image depths (nm) and extract values into an array
depthtxt=File.openDialog("Select .txt file containing depth list for all images (no heathers)");
filestring=File.openAsString(depthtxt);
rows=split(filestring, "\n");
depths=newArray(rows.length);
for(i=0; i<rows.length; i++){
depths[i]=parseFloat(rows[i]);
}

//Select .txt file of image dimensions XY (nm) and extract values into an array
XYvalues_txt=File.openDialog("Select .txt file containing XY list for all images (no heathers)");
filestring=File.openAsString(XYvalues_txt);
rows=split(filestring, "\n");
XY=newArray(rows.length);
for(i=0; i<rows.length; i++){
XY[i]=parseFloat(rows[i]);
}

//Get thresdholding value to know how to filter the background
//Dialog.create("Background filtering depending on imaged type");
//Dialog.addMessage("Depending on the type of image the code will need a different \nbackground filter number. Dile below according to these recomendations:", 12, "#393332");
//Dialog.addMessage("Same height objects on a flat background (e.g. DNA) =  0.050 - 0.06", 16, "#ee360f");
//Dialog.addMessage("Two distinct heights objects on a flat background (e.g. Sacculi) =  0.06 - 0.2", 16, "#0f67ee");
//Dialog.addSlider("Background Threshold:", 0.025, 0.500, 0.005);
//Dialog.addSlider(label, min, max, default);
//Dialog.show();
//imageTypeIndex = Dialog.getNumber();
imageTypeIndex = 0.1;

//define functions to detect the peaks and transition points in the histogram of intensities

// Function to find the main peak (highest intensity count)
function findMainPeak(hist) {
    maxCount = 0;
    peakIndex = 0;
    for (i = 0; i < lengthOf(hist); i++) {
        if (hist[i] > maxCount) {
            maxCount = hist[i];
            peakIndex = i;
            //i=1e9; // This is because the background peak will always be on the left of the image, so in reality this is finidng the first peak.
        }
    }
    return peakIndex;
}

// Function to find the transition point after the peak
function findTransitionPoint(hist, imageTypeIndex, peakIndex) {
    for (i = peakIndex + 1; i < lengthOf(hist) - 1; i++) {
        if (hist[i] < imageTypeIndex * hist[peakIndex]) {  // This value is what determines if the background is detected accurately - make it an option for users to change this.
            return i;
        }
    }
    return lengthOf(hist) - 1;  // If no clear transition, return last index
}

//Give the number of slices to cut the image into
Slices = getNumber("Number of slices to make from the image (max 255)", 255);

//Ask user if they want to save the filtered image (true = save), (false = delete)
SaveFiltered = false;

//Batch processing loop starts
for (j=0; j<list.length; j++) {
	
	//Open image from the list
	open(dir1 + list[j]);
	//File name in form image.tif
	
	//File name in form image_filtered
	name1 = File.nameWithoutExtension +"_F";
	name2 = File.nameWithoutExtension;
	name3 = File.nameWithoutExtension + "_";

	
	//Scale the image down to 520x520
	run("Scale...", "x=- y=- width=520 height=520 interpolation=Bilinear average create");

	//filter to be able to better distinguish the objects from the background
	run("Gaussian Blur...", "sigma=2");
	
	//Save this as filtered image to be able to do the slicing later on this one
	saveAs("tiff", dir1+name1);
	
	//Close everything and open only the filtered image to make sure the original image is closed. 
	run("Close All");
	open(dir1 + name1 + ".tif");
	name0 = File.name;
	name0_noExt = File.nameWithoutExtension;
	

	
    nBins = 256;
	run("Clear Results");
	//row=0;
	values = newArray(nBins);
	bins = newArray(nBins);
	getHistogram(values, counts, nBins);
	//Save all the count values from all the pores in "ColourCount.csv
    	//headline2 = "t,values,counts";
		//File.append(headline2, dir1+"Histogram"+name0+".csv");
    for (t = 0; t < nBins; t++) {
    	setResult("Value", t, values[t]); //intensity bins (I think middle of it already) or maybe t
    	setResult("Count", t, counts[t]); //counts in the image /so the peaks!
   
	}
	

	//Finde the maximum intensity value to do the conversion from intensity to slices later
	selectWindow(""+name0+"");
	run("Set Measurements...", "area mean standard modal min centroid center perimeter integrated display redirect=None decimal=2");
	run("Measure");

	maxIntensity = getResult("Max", nResults-1);
	close("Results"); // Close results table to avoid clutter
	//print("Max intensity " + maxIntensity);
	
	//Apply functions to find the point where the background (main peak) stops and the objects start (rest of the data in the image)
	peakIndex = findMainPeak(counts);
	transitionIndex = findTransitionPoint(counts, imageTypeIndex, peakIndex);
	transitionIntensityStart = values[transitionIndex]; //the intensity values are divided in the bins not in the counts


	//calculate the exact value of intensity (which is not the start of the bin but the middle)
	transitionIntensity = transitionIntensityStart-((transitionIntensityStart-values[transitionIndex-1])/2);

	//Conversion of intensity value of the background transition to cut the stack that we are going to make
	sliceTransition_inversed = (transitionIntensity*Slices)/maxIntensity; //using the values calculated above
      //print("slice transition Inversed =" + round(sliceTransition_inversed));
	sliceTransition = abs(Slices-round(sliceTransition_inversed));
	  //print("slice transition =" + sliceTransition);

	//calculate conversion factors from pixels to nm of image
	Conversion_depth = depths[j]/Slices;
	Conversion_XY = XY[j]/520;
	
print("Starting to slice now...");

	run("Close All");

	//Reduces visual outputs
	setBatchMode(true);

	//Create the complete stack of all the data
	for(i = 0; i < Slices; i++) {
		
		//Open greyscale image
		open(dir1 + name1 + ".tif");
	
		//Convert to 8-bit
		run("8-bit");
		
		//Threshold image
		setAutoThreshold("Otsu");
		
		a = 0;
		b = Slices - i;
		
		setThreshold(a, b);
		
		setOption("BlackBackground", false);
		run("Convert to Mask");
		
	}
	
	
	//If requested, remove filtered image
	if (SaveFiltered == false) {
		File.delete(dir1+name1+".tif")
	}
	
	//Stack images
	name4 = name2+"_stack";
	run("Images to Stack", "title=[] use");
	
	//Save the stack as Image Sequence for further analysis. Saves in a folder named Filename_stack in stacks folder
//Make this OPTIONAL - do you want to save the stack as image sequence?
	savepoint = dir2 + name2 + "_stack" + File.separator;
	File.makeDirectory(savepoint);
	run("Image Sequence... ", "format=TIFF name="+name3+" digits=3 save=["+savepoint+"]");
	
	//change properties to convert pixels into nm			
	Stack.setXUnit("nm");
	run("Properties...", "channels=1 slices="+Slices+" frames=1 pixel_width="+Conversion_XY+" pixel_height="+Conversion_XY+" voxel_depth="+Conversion_depth+"");
	
	//Save stack as .tiff_complete - now it has the right dimensions
	saveAs("tiff", dir2+name4);

print("Stacking complete");

//Crop the stack so that it only contains the objects, without the image background
startSlice = 1;  // Fiji starts at 1
endSlice = round(sliceTransition);  // Slices are 1-based
stackSize = abs(endSlice-startSlice)+1;
name5 = name2+"_objects_Stack";
run("Duplicate...", "title="+name5+" duplicate range="+startSlice+"-"+endSlice);
saveAs("tiff", dir3+name5);

print("Identification of objects finished and stack cropped on slice number: "+sliceTransition+"");

run("Close All");//there are to stacks so we need to make sure we only select the cropped one from now on


open(dir3 + name5 + ".tif");
			//Remove    dir0 = getDirectory("Select folder containing stacks");
			
//change properties to convert pixels into nm			
//Stack.setXUnit("nm");
//run("Properties...", "channels=1 slices="+stackSize+" frames=1 pixel_width="+Conversion_XY+" pixel_height="+Conversion_XY+" voxel_depth="+Conversion_depth+"");

run("Invert", "stack");

//change data type to float
run("32-bit");

//Use MorphoLibJ to prepare image to be able to analyse volume.
run("Connected Components Labeling", "connectivity=26 type=[8 bits]");

run("Set Label Map", "colormap=Ice background=Black shuffle");

//Analyse all properties in 3D with MorphoLibJ including Volume
run("Analyze Regions 3D", "voxel_count volume surface_area mean_breadth sphericity euler_number bounding_box centroid equivalent_ellipsoid ellipsoid_elongations max._inscribed surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26");


name_results = name2+"_MorpholibJ_complete_results";
//saveAs("Results", "C:/Users/bi1lp/Desktop/testing_code3/only_1_image/only_1_image_Stacks/DNA_0001_objects_Stack-lbl-morpho.csv");
saveAs("Results", dir3 + name_results + ".csv");
close("*.csv");
//Table.deleteRows(0, 255, ""+name_results+"");
//Convert to 8-bit to be able to run the 3D object ROI
run("8-bit"); //maybe I need to remove this.


//code that uses 3D ROI manager to produce labels with the Volume map. //https://imagejdocu.list.lu/plugin/stacks/3d_roi_manager/start //cite 3D Suite and MorpholibJ
requires("1.46g");
rename("image");
//saveAs("Jpeg", dir1+"image");
w=getWidth();
h=getHeight();
s=nSlices();
selectWindow("image");
temp=getDirectory("home");
//print("temp",temp);
run("3D Manager");
Ext.Manager3D_AddImage();
Ext.Manager3D_Measure();
newImage("color size", "8-bit Black", w, h, s);
selectWindow("color size");
Ext.Manager3D_Count(nb);
Ext.Manager3D_Measure3D(0,"Vol",V);
max=V; min=V;
// loop to find max and min volumes
for(i=1;i<nb;i++) {
	Ext.Manager3D_Measure3D(i,"Vol",V);
	if(V>max) {
		max=V;
	}
	if(V<min){
		min=V;
	}		
}
Ext.Manager3D_MonoSelect();
Ext.Manager3D_DeselectAll();
for(i=0;i<nb;i++) {
     Ext.Manager3D_Measure3D(i,"Vol",V);
     s=(V-min)/(max-min);
     Ext.Manager3D_Select(i);
     Ext.Manager3D_FillStack(255*s, 255*s, 255*s);
}

Ext.Manager3D_SelectAll;
Ext.Manager3D_Delete;


run("Fire");
//change properties to convert pixels into nm			
	Stack.setXUnit("nm");
	run("Properties...", "channels=1 slices="+stackSize+" frames=1 pixel_width="+Conversion_XY+" pixel_height="+Conversion_XY+" voxel_depth="+Conversion_depth+"");
name4=name1+"_labelled_objects";
saveAs("tiff", dir3+name4); //This can be used for further 3D plotting (it might be better to transform into Greys LUTs

name5=name1+"_labelled_objects_LUTFire";
//final_image_slices = getSliceNumber();
print("final stack size "+stackSize+"");
//run("Duplicate...", "title="+name5+" duplicate range="+final_image_slices+"-"+final_image_slices+"use");
run("Z Project...", "projection=[Max Intensity]");
run("RGB Color");
saveAs("Jpeg", dir1+name5);

selectWindow("MeasureTable");
saveAs("Results", dir3 + File.nameWithoutExtension + "_measureTable.csv");
//Table.deleteRows(0, 255, File.nameWithoutExtension + "_measureTable.csv");
close("*.csv");
close("Res*");

//setSlice(s/2+1);
//run("Enhance Contrast", "saturated=0.35");
print("finished analysing objects in 3D and the stack has colours based on Volume, see image "+name0+"in the results folder");

//Closing everything before next image starts
run("Close All");
//run("Close");
//run("Close-");
}