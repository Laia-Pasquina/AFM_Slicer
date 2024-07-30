/*
 * Program to perform automated measurements on all the stack from an AFM image, obtaining areas of each slice and HCFA
 * 
 * Authors: Dr Laia Pasquina-Lemonche & Matthew Barker, University of Sheffield, UK, 
 * 			
 * Date of Original: 12th May 2020
 * 
 * UPDATE: Automated almost all features, added analysis methods to obtain xo, 2*sigma, and produce
 * the graph of log(HCFA) against slice depth (Edited by Matthew Barker, University of Sheffield, UK)
 * Date: 16th October 2023
 */

run("Close All");
print("\\Clear");

print("  ");
print("Code is starting");
print("  ");

print("  ");
print("Select the folder containing the stack of images");
print("  ");
dir1 = getDirectory("Select stack folder containing image slices");

print("  ");
print("Select a folder to put the results into");
print("  ");
dirtemp = getDirectory("Select the folder to have the results put into");
dir2 = dirtemp + File.getName(dir1) + "_results" + File.separator;
File.makeDirectory(dir2);
list = getFileList(dir1);

//YES calculates the half of cumulative fraction of total area later. NO does total number of pores 
HCFAYN = "YES";

//Obtain image dimensions
print("  ");
print("Enter image dimensions");
print("  ");

Dialog.create("Dimensions");
	Dialog.addNumber("Image Length/Width (nm):", 200);
	Dialog.addNumber("Image Depth (nm):", 20);
Dialog.show();

XYSize = Dialog.getNumber();
conversion = XYSize / 520;
Depth = Dialog.getNumber();
Conversion = Depth/255;

number_of_repetitions = list.length - 1;

//Hide all the system processes
setBatchMode(true);

//Create the array for the final result to be stored in and the file to store this in
HCFA = newArray(number_of_repetitions+1);
headline = "Depth_slice_number,HCFA";
File.append(headline, dir2 + "HCFA" + ".csv");

//Create arrays to number of pores of different sizes and a file to save these in
Yellow = newArray(number_of_repetitions);
Green = newArray(number_of_repetitions);
Magenta = newArray(number_of_repetitions);
Blue = newArray(number_of_repetitions);
DepthArray = newArray(number_of_repetitions);
Total_count = newArray(number_of_repetitions); //counts total pores per slice

headline2 = "Depth_slice_number,Yellow_pores,Green_pores,Magenta_pores,Blue_pores,Total_number_pores";
File.append(headline2, dir2 + "ColourCount" + ".csv");

print("  ");
print("Analysing slices. Results are shown being printed");
print("  ");

for (j = 0; j <= number_of_repetitions; j++) {
	//reset ROI manager, images and results
	if (roiManager("count")>0) {
		roiManager("Deselect");
		roiManager("Delete");
	}
	run("Close All");
	run("Clear Results");
	
	//Open image
	open(dir1 + list[j]);
	
	if (j == 127) {
		print("Process halfway complete");
	}
	
	//Convert pixels to nm
	run("Properties...", "channels=1 slices=1 frames=1 unit=nm pixel_width="+conversion+" pixel_height="+conversion+" voxel_depth="+conversion+"");
	
	//Threshold the image to convert into the right format
	setAutoThreshold("Otsu dark");
	
	//Apply threshold. true puts holes in white, false puts them in black
	setOption("BlackBackground", true);
	run("Convert to Mask");
	
	//Obtain the table using ROIManager, measure
	run("Analyze Particles...", "size=2-Infinity display include add lable");
	resetThreshold();
	
	//Visualise nothing
	roiManager("Show None");
	
	if (roiManager("count")>0) {
		number_of_rois = roiManager("count");
		
		//Create variables to count pores in each slice of different colours
		yellow_rois = 0;
		green_rois = 0;
		magenta_rois = 0;
		blue_rois = 0;
		
		//Classify rois by area and count how many of each colour
		for (i = 0; i < number_of_rois; i++) {
			//Select an ROI
			roiManager("select", i);
			
			Area = getResult("Area", i);
			
			//Assign a colour depending on area
			if (Area <= 20) {
				Roi.setStrokeColor("yellow");
				Roi.setStrokeWidth(5);
				yellow_rois = yellow_rois + 1;
			}
			
			if (Area > 20 && Area <= 500) {
				Roi.setStrokeColor("green");
				Roi.setStrokeWidth(5);
				green_rois = green_rois + 1;
			}
			
			if (Area > 500 && Area <= 1500) {
				Roi.setStrokeColor("magenta");
				Roi.setStrokeWidth(5);
				magenta_rois = magenta_rois + 1;
			}
			
			if (Area > 1500) {
				Roi.setStrokeColor("blue");
				Roi.setStrokeWidth(5);
				blue_rois = blue_rois + 1;
			}
			
			//Add to the Overlay
			Overlay.addSelection();
		}
		
		//Save processed image
		saveAs("jpeg", dir2+list[j]);
		
		//Allocate the count of pores to the colour arrays and total
		Yellow[j] = yellow_rois;
		Green[j] = green_rois;
		Magenta[j] = magenta_rois;
		Blue[j] = blue_rois;
		Total_count[j] = number_of_rois;
		DepthArray[j] = j;
		
		//Save all the count values from all the pores in "ColourCount.csv
		contentline2 = "" + j + "," + Yellow[j] + "," +Green[j]+","+ Magenta[j]+ ","+ Blue[j]+","+ Total_count[j];
		File.append(contentline2, dir2+"ColourCount"+".csv");
		
		//Create an array and allocate all values of area
		to_sort = newArray(number_of_rois);
		Total = 0;
		
		for (i = 0; i < number_of_rois; i++) {
			//Select an ROI
			roiManager("select", i);
			
			//Allocate values to new array
			Area = getResult("Area", i);
			to_sort[i] = Area;
			
			//Calculate total area
			Total = Total + Area;
		}
		
		//Sort the values of area by size (small->large)
		Sorted = Array.sort(to_sort);
		
		//Define arrays needed to calculate cumulative fraction of total area per slice
		cum_value = newArray(number_of_rois + 1);
		cum_fraction = newArray(number_of_rois + 1);
		cum_value[0] = Sorted[0];
		cum_fraction[0] = cum_value[0] / Total;
		
		for (i = 1; i < number_of_rois; i++) {
			//Calculate cumulative value
			cum_value[i] = cum_value[i - 1] + Sorted[i];
			//Calculate cumulative fraction of total area
			cum_fraction[i] = cum_value[i] / Total;
			
			if (HCFAYN == "YES") {
				//Calculate half of the cumulative fraction of the total area (HCFA) nm^2
				if (cum_fraction[i] > 0.4 && cum_fraction[i] < 0.55) {
					HCFA_in = i;
					HCFA[j] = Sorted[HCFA_in];
				}
			}
			if (HCFAYN == "NO") {
				//If not HCFA, just use total pores
				HCFA[j] = Total;
			}
		}
		
		//Create final results table with the raw Area, the sorted area and the cumulative fraction for each slice
		table1 = "Results_table";
		Table.create(table1);
		
		for (i = 0; i < number_of_rois; i++) {
			Area = getResult("Area", i);
			Table.set("Raw Area", i, Area);
			Table.set("Area Sorted", i, Sorted[i]);
			Table.set("Cumulative Fraction", i, cum_fraction[i]);
		}
		
		saveAs("Results", dir2 + File.nameWithoutExtension + ".csv");
	}
	
	//If no ROIs, set HCFA = 0
	else{
		HCFA[j] = 0;
	}
	
	//Save all HCFA values from all repetitions in one file (Final.csv)
	ValueLine = HCFA[j];
	if (ValueLine > 0) {
		contentline = "" + j + "," + HCFA[j];
		File.append(contentline, dir2 + "HCFA" + ".csv");
	}
	
	//Close random table that keeps appearing every iteration
	name = File.nameWithoutExtension + ".csv";
	x = isOpen(name);
	if(x == true) {
		selectWindow(name);
		run("Close");
	}
}

//Close results table
name2 = "Results";
if (isOpen(name2)) {
	selectWindow(name2);
	run("Close");
}

//Remove zero values for depth array that appears for some reason
for (i = 0; i < DepthArray.length; i++) {
	if (DepthArray[i] == 0 && Total_count[i] == 0) {
		DepthArray = Array.deleteIndex(DepthArray, i);
		Total_count = Array.deleteIndex(Total_count, i);
		HCFA = Array.deleteIndex(HCFA, i);
		i--;
	}
}

//Fit Gaussian and retrieve parameters
Fit.doFit("Gaussian", DepthArray, Total_count);
x = DepthArray;
a = Fit.p(0);
b = Fit.p(1);
c = Fit.p(2);
d = Fit.p(3);
y = newArray(DepthArray.length);

//Function to calculate Gaussian values as Fit.plot didn't want to work
for (i = 0; i < x.length; i++) {
	y[i] = a+(b-a)*Math.exp(-(x[i]-c)*(x[i]-c)/(2*d*d));
}

//Plot the data and fitted Gaussian
Plot.create("Number of pores per slice", "Slice Number", "Number of Pores", DepthArray, Total_count);
Plot.add("line", x, y);
Plot.show();

//Obtain xo and 2*sigma from the Gaussian
xo = round(c);
sigma2 = round(2*d);
positive_sigma = xo + sigma2;
negative_sigma = xo - sigma2;
//Retrieve the HCFA values for xo and 2*sigma values
HCFA_bottom = 0;
HCFA_top = 0;
k=0;
m=0;

for (i = 0; i < DepthArray.length; i++) {
	if (DepthArray[i] == xo) {
		HCFA_xo = HCFA[i];
	}
	if (DepthArray[i] == negative_sigma) {
		HCFA_bottom = HCFA[i];
		k = i;
	}
	if (DepthArray[i] == positive_sigma) {
		HCFA_top = HCFA[i];
		m = i;
	}
}

Error = 0;
//double check that the negative sigma is not falling outside of list
if(HCFA_bottom == 0){
	for(i=0; i < HCFA.length; i++) {
		if(HCFA[i] > 0) {
		HCFA_bottom = HCFA[i];
		negative_sigma = DepthArray[i];
		Error = 1;
		break;
		}
	}
}
//double check that the positive sigma is in the list (which is an error from the way code 2 works)
if(HCFA_top == 0){
	for (i = 0; i < DepthArray.length; i++) {
		if(DepthArray[i] == positive_sigma-1){
		k = i;
		HCFA_top = HCFA[k];
		}else{
		
		Diff_sigma = newArray(DepthArray.length);
			for(i = 0; i < DepthArray.length; i++){
			Diff_sigma [i] = abs(DepthArray[i]-positive_sigma);
			}
		Stats = Array.getStatistics(Diff_sigma, min_Diff, max_Diff, mean_Diff, stdDev_Diff);
		print(Stats);
		print(Stats[1]);
			for(i = 0; i <= Diff_sigma.length; i++){
				if (Diff_sigma [i] == Stats[1]){
					k = i;
					HCFA_top = HCFA[k];
				}
			}
	
		}
	 Error = 2;	
	}
}

//Calculating diameter of pores if they were perfectly circular with the corresponding measured areas
Diam_xo = 2*sqrt(HCFA_xo/PI);
Diam_bottom = 2*sqrt(HCFA_bottom/PI);
Diam_top = 2*sqrt(HCFA_top/PI);

//Create a new folder to save extra results in
//print("  ");
//print("Select folder to save results folder in");
//print("  ");
//dir1 = getDirectory("Select folder to create results folder inside");
//dir2 = dir1 + "Analysed_results_for_graph" + File.separator;
//File.makeDirectory(dir2);

selectWindow("Number of pores per slice");
saveAs(".PNG", dir2+"Gaussian_and_fit");


Depth_nm_bottom = negative_sigma*Conversion;
Depth_nm_xo = xo*Conversion;
Depth_nm_top = positive_sigma*Conversion;


//Setup file in designated folder
contentline3 = " " + "," + "Slice" + "," + "Depth (nm)" + "," + "HCFA" + "," + "Diameter";
contentline4 = "xo-2sigma" + "," + negative_sigma + "," + Depth_nm_bottom + "," + HCFA_bottom + "," + Diam_bottom; 
contentline5 = "xo" + "," + xo + "," + Depth_nm_xo + "," + HCFA_xo + "," + Diam_xo;
contentline6 = "xo+2sigma" + "," + positive_sigma + "," + Depth_nm_top + "," + HCFA_top + "," + Diam_top;

File.append(contentline3, dir2 + "Final" + ".csv");
File.append(contentline4, dir2 + "Final" + ".csv");
File.append(contentline5, dir2 + "Final" + ".csv");
File.append(contentline6, dir2 + "Final" + ".csv");

//Add error message if the HCFA_bottom and/or HCFA_top couldn't be calculated with 2 sigma
if(Error == 1){
	
	Bottom_error = "Value of -2 sigmas not in the list so top error bar is first HCFA value";
	contentline7 = "Error message" + "," + Bottom_error;
	File.append(contentline7, dir2 + "Final" + ".csv");
}

//I doubt I will need to put this, probably remove it!
if(Error == 2){
	
	//if(Bottom_error.length > 0){
	Top_error = "No bottom error bar because +2sigma not in the HCFA list, I chosen the previous value";
	contentline8 = "Error message_2" + "," + Top_error;
	File.append(contentline8, dir2 + "Final" + ".csv");
	//}
	//Top_error = "No bottom error bar because sigma distance from xo not in the HCFA list";
	//contentline8 = "Error message" + "," + Top_error;
	//File.append(contentline8, dir2 + "Final" + ".csv");
	
}

//run("Close All");
//print("\\Clear");

index_diff = abs(m-k);
HCFA_sigmas = newArray(index_diff);
DepthArray_sigmas = newArray(index_diff);

//Remove values outside of two sigma values so only plot LOG of HCFA graph within the two sigmas
for (i = k; i <= m; i++) {
	j = i - k;
	//if (i >= k && i <= m){
	//if ((HCFA[i]<= HCFA_bottom) && (HCFA[i] >= HCFA_top)){
	HCFA_sigmas[j] = HCFA[i];
	DepthArray_sigmas[j] = DepthArray[i];
	//print("inside loop, i = "+i);
	//}
	//else {
	//	print("did this work?");
	//	break;
	//}
}

//Log HCFA values and remove any zero values at the same time, as well as converting depth into nm
for (i = 0; i < HCFA_sigmas.length; i++) {
	if (HCFA_sigmas[i] > 0) {
		HCFA_sigmas[i] = log(HCFA_sigmas[i]);
		//Convert all the other Depth values in nm
		//Depth_HCFA[i] = (Depth * Depth_HCFA[i]) / (list.length);
		DepthArray_sigmas[i] = (DepthArray_sigmas[i]*Conversion);
	}
	else if (HCFA_sigmas[i] == 0) {
		HCFA_sigmas = Array.deleteIndex(HCFA_sigmas, i);
		DepthArray_sigmas = Array.deleteIndex(DepthArray_sigmas, i);
		i--;
	}
	else {
		break;
	}
}

//Plot the log graph
Plot.create("Log Graph", "Depth (nm)", "log(HCFA) (nm^2)", DepthArray_sigmas, HCFA_sigmas);
Plot.show();
selectWindow("Log Graph");
saveAs(".PNG", dir2+"HCFA_LOG_Graph");

//Fit straight line to the log graph in order to get exponential coefficient
Fit.doFit("Straight Line", DepthArray_sigmas, HCFA_sigmas);
B = -Fit.p(1);
//print("Exponential coefficient of the log graph: ", B);

//Set up a csv file for the log graph
contentlineA = "Depth (nm)" + "," + "log_HCFA (nm^2)";
File.append(contentlineA, dir2 + "HCFA_log" + ".csv");
for (i = 0; i < HCFA_sigmas.length; i++) {
	contentlineC = "" + DepthArray_sigmas[i] + "," + HCFA_sigmas[i];
	File.append(contentlineC, dir2 + "HCFA_log" + ".csv");
}

//Add exp coefficient to the Final.csv
contentlineB = "exp coefficient" + "," + B;
File.append("", dir2 + "Final" + ".csv");
File.append(contentlineB, dir2 + "Final" + ".csv");

print("Code has finished. Results are in the created folder");