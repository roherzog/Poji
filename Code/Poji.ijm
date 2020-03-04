
/*This macro is related to the publication "Poji: a Fiji-based tool for analysis of podosomes and associated proteins" in Journal of Cell Science by Herzog et al. 2020 (doi: XXX).
For advice on using this macro, as well as for concept of proof, please refer to the linked publication and also to the user guide that is added in the supplementary information.
If you publish data that were obtained by using this macro, please cite the original publication accordingly!
@ Author: Robert Herzog, 2020
*/

//Selection of Channels and Names
Dialog.create("Define channel selection");
Dialog.addMessage("Channel 1 HAS TO BE the podosome defining channel!\nOtherwise the macro can not define the podosomes correctly.");
Dialog.addString("Channel 1:", "F-actin"); //Change "F-actin" for preferred name for channel 1
Dialog.addString("Channel 2:", "Vinculin"); //Change "Vinculin" for preferred name for channel 2
Dialog.addString("Channel 3:", "Myosin IIA"); //Change "Myosin IIA" for preferred name for channel 3
Dialog.addString("Channel 4:", "Additional"); //Change "Additional" for preferred name for channel 4
Dialog.addSlider("No. of channels to be analysed:", 1, 4, 3); //Change the last number (3) to the preferred number of channels (must be between 1-4)
Dialog.show();
Channame1=Dialog.getString();
Channame2=Dialog.getString();
Channame3=Dialog.getString();
Channame4=Dialog.getString();
Channumber=Dialog.getNumber();
Chan1=getDirectory("Select source folder for " + Channame1 + " images");
list1=getFileList(Chan1);
Chan1_temp=File.getParent(Chan1) + "/Analysis_temp_" + Channame1 + "/";
File.makeDirectory(Chan1_temp);
if (Channumber>1) {
	Chan2=getDirectory("Select source folder for " + Channame2 + " images");
	list2=getFileList(Chan2);
	Chan2_temp=File.getParent(Chan2) + "/Analysis_temp_" + Channame2 + "/";
	File.makeDirectory(Chan2_temp);
	if (list1.length-list2.length!=0) {
		exit("Please make sure that there is the same amount of data in every folder!\nMake sure that they are in the right order! Then restart the macro!");
	}
	if (Channumber>2) {
		Chan3=getDirectory("Select source folder for " + Channame3 + " images");
		list3=getFileList(Chan3);
		Chan3_temp=File.getParent(Chan3) + "/Analysis_temp_" + Channame3 + "/";
		File.makeDirectory(Chan3_temp);
		if (list1.length-list3.length!=0) {
			exit("Please make sure that there is the same amount of data in every folder!\nMake sure that they are in the right order! Then restart the macro!");
		}
		if (Channumber>3) {
			Chan4=getDirectory("Select source folder for " + Channame4 + " images");
			list4=getFileList(Chan4);
			Chan4_temp=File.getParent(Chan4) + "/Analysis_temp_" + Channame4 + "/";
			File.makeDirectory(Chan4_temp);
			if (list1.length-list4.length!=0) {
				exit("Please make sure that there is the same amount of data in every folder!\nMake sure that they are in the right order! Then restart the macro!");
			}
		}
	}
}
Output=getDirectory("Select output folder for the results");
//Selection of Analysis parameters
Dialog.create("Choose analysis and data saving options"); //Change "true" for "false" or vice versa to (de-)activate checkboxes by default
Dialog.addCheckbox("normalise fluorescence intensity in cell area?", false);
Dialog.addCheckbox("additionally select podosome clusters?", true);
Dialog.addCheckbox("identical cell and cluster areas for all images?", false);
Dialog.addCheckbox("identical detection conditions for all images?", false);
Dialog.addCheckbox("calculate average profiles?", true);
Dialog.addCheckbox("also calculate individual profiles? (very slow!)", false);
Dialog.addMessage("Data saving options");
Dialog.addNumber("decimals in profile results:", 3); //Change "3" for preferred number of decimals (max. 9)
Dialog.addChoice("data format for result tables?", newArray(".txt", ".csv", ".tsv")); //Set the preferred ending to the first position to select it by default 
Dialog.addChoice("save data from analysis?", newArray("essential", "all")); //Set preferred option to first position to select it by default
Dialog.show();
norm_cell=Dialog.getCheckbox();
cluster=Dialog.getCheckbox();
sameROI=Dialog.getCheckbox();
same_detec=Dialog.getCheckbox();
Profile=Dialog.getCheckbox();
single_profiles=Dialog.getCheckbox();
decimal=Dialog.getNumber();
data_ending=Dialog.getChoice();
data_save=Dialog.getChoice();
//Selection and saving of ROIs per cell and saving temporary image files (multiple times if multiple cells are on one image) 
for (aaa=0; aaa<list1.length; aaa++) {
	if (!endsWith(list1[aaa], "/")) {
		path1=Chan1+list1[aaa];
		open(path1);
		name_a=getTitle();
		name_a2=File.nameWithoutExtension;
		bit=bitDepth();
		if (bit!=8 && bit!=16) {
			showMessage("Macro stopped!", "Only 8- and 16-bit images supported! \nPlease adjust your images accordingly. \nPlease delete the 'Analysis_temp' folders that appeared \nin your source folder before you restart the macro.");
			run("Close All");
			exit();
		}
		if (sameROI==0 || aaa==0) {
			roiManager("Reset");
			setBatchMode(false);
			while (roiManager("Count")==0) {
				waitForUser("Select Cell Area(s)", "Please select a ROI around the cell(s) and \nadd it/them to the ROI manager (press 't').\nClick 'OK' to proceed after all cells are selected.");
			}
		}
		setBatchMode(true);
		nRois=roiManager("Count");
		selectImage(name_a);
		close();
		for (abc=1; abc<=nRois; abc++) {
			if (nRois>1) {
				File.makeDirectory(Output + "/" + name_a2 + "_Cell_" + abc + ".tiff");
				File.makeDirectory(Output + "/" + name_a2 + "_Cell_" + abc + ".tiff/ROIs");
				roiManager("Select", abc-1);
				roiManager("Save", Output + "/" + name_a2 + "_Cell_" + abc + ".tiff/ROIs/ROI_Cell.roi");
				open(path1);
				saveAs("Tiff", Chan1_temp + "/" + name_a2 + "_Cell_" + abc + ".tiff");
			} else {
				File.makeDirectory(Output + "/" + name_a2 + ".tiff");
				File.makeDirectory(Output + "/" + name_a2 + ".tiff/ROIs");
				roiManager("Select", abc-1);
				roiManager("Save", Output + "/" + name_a2 + ".tiff/ROIs/ROI_Cell.roi");
				open(path1);
				saveAs("Tiff", Chan1_temp + "/" + name_a2 + ".tiff");
			}
			close();
			if (Channumber>1) {
				if (!endsWith(list2[aaa], "/")) {
					open(Chan2+list2[aaa]);
					name_b2=File.nameWithoutExtension;
					if (nRois>1) {
						saveAs("Tiff", Chan2_temp + "/" + name_b2 + "_Cell_" + abc + ".tiff");
					} else {
						saveAs("Tiff", Chan2_temp + "/" + name_b2 + ".tiff");
					}
					close();
				}
				if (Channumber>2) {
					if (!endsWith(list3[aaa], "/")) {
						open(Chan3+list3[aaa]);
						name_c2=File.nameWithoutExtension;
						if (nRois>1) {
							saveAs("Tiff", Chan3_temp + "/" + name_c2 + "_Cell_" + abc + ".tiff");
						} else {
							saveAs("Tiff", Chan3_temp + "/" + name_c2 + ".tiff");
						}
						close();
					}
					if (Channumber>3) {
						if (!endsWith(list4[aaa], "/")) {
							open(Chan4+list4[aaa]);
							name_d2=File.nameWithoutExtension;
							if (nRois>1) {
								saveAs("Tiff", Chan4_temp + "/" + name_d2 + "_Cell_" + abc + ".tiff");
							} else {
								saveAs("Tiff", Chan4_temp + "/" + name_d2 + ".tiff");
							}
							close();
						}
					}
				}
			}
		}
	}
	setBatchMode(false);
}
list1_temp=getFileList(Chan1_temp);
if (Channumber>1) {
	list2_temp=getFileList(Chan2_temp);
	if (Channumber>2) {
		list3_temp=getFileList(Chan3_temp);
		if (Channumber>3) {
			list4_temp=getFileList(Chan4_temp);
		}
	}
}
//Selection and saving of ROIs around podosome cluster
if (cluster==1 && sameROI==0) {
	for (aaa=0; aaa<list1_temp.length; aaa++) {
		roiManager("Reset");
		open(Chan1_temp+list1_temp[aaa]);
		name=getTitle();
		roiManager("Open", Output + "/" + name + "/ROIs/ROI_Cell.roi");
		roiManager("Select", 0); 
		run("Flatten");
		name_x=getTitle(); 
		roiManager("Reset"); 
		selectImage(name);
		close();
		waitForUser("Select Podosome Cluster(s)", "Please select a ROI around the podosome cluster(s)\nand add it/them to the ROI manager (press 't').\nClick 'OK' to proceed after all clusters are selected.\nYou can proceed without selecting a cluster, as well."); 
		if (roiManager("Count")!=0) {
			roiManager("Save", Output + "/" + name + "/ROIs/ROI_Cluster.zip");
		}
		selectImage(name_x);
		close();
	}
} else if (cluster==1 && sameROI==1) {
	for (aaa=0; aaa<nRois; aaa++) {
		roiManager("Reset");
		open(Chan1_temp+list1_temp[aaa]);
		name=getTitle();
		roiManager("Open", Output + "/" + name + "/ROIs/ROI_Cell.roi");
		roiManager("Select", 0); 
		run("Flatten");
		name_x=getTitle(); 
		roiManager("Reset"); 
		selectImage(name);
		close();
		waitForUser("Select Podosome Cluster(s)", "Please select a ROI around the podosome cluster(s)\nand add it/them to the ROI manager (press 't').\nClick 'OK' to proceed after all clusters are selected.\nYou can proceed without selecting a cluster, as well."); 
		if (roiManager("Count")!=0) {
			for (aab=0; aab<list1_temp.length/nRois; aab++) {
				roiManager("Save", Output + "/" + list1_temp[(aab*nRois) + aaa] + "/ROIs/ROI_Cluster.zip");
			}
		}
		selectImage(name_x);
		close();
	}
}
//Manual definition of analysis parameters
noise=newArray(list1_temp.length);
smoothsteps=newArray(list1_temp.length);
circlesize=newArray(list1_temp.length);
squaresize=newArray(list1_temp.length); 
noise[0]=20; //Replace with noise tolerance value that is shown by default
smoothsteps[0]=3; //Replace with number of smoothing steps that is shown by default
circlesize[0]=15; //Replace with default size of circular podosome selections
squaresize[0]=15; //Replace with change default size of square podosome selections 
prev_image="Prev_Image";
for (aaa=0; aaa<list1_temp.length; aaa++) {
	if (aaa>0) {
		noise[aaa]=noise[aaa-1];
		smoothsteps[aaa]=smoothsteps[aaa-1];
		circlesize[aaa]=circlesize[aaa-1];
		squaresize[aaa]=squaresize[aaa-1];
	}
	setBatchMode(true);
	roiManager("Reset");
	open(Chan1_temp+list1_temp[aaa]);
	name=getTitle();
	getPixelSize(unit_init, x_init, y_init);
	roiManager("Open", Output + "/" + name + "/ROIs/ROI_Cell.roi");
	roiManager("Select", 0); 
	roiManager("Set Color", "yellow"); 
	roiManager("Save", Output + "/" + name + "/ROIs/ROI_Cell.zip");
	File.delete(Output + "/" + name + "/ROIs/ROI_Cell.roi");
	selectWindow("Log");
	run("Close");
	run("Flatten");
	name_x=getTitle(); 
	selectImage(name); 
	close();
	preview=1;
	while (preview==1) {
		if (same_detec==0 || aaa==0) {
			setBatchMode(false);
			Dialog.create("Choose the parameters");
			Dialog.addMessage("Please choose options for the podosome detection. \nCell number " + aaa + 1);
			Dialog.addNumber("noise tolerance:", noise[aaa]); 
			Dialog.addNumber("smoothing steps:", smoothsteps[aaa]); 
			Dialog.addMessage("Sizes of isolated podosome images (odd numbers).");
			Dialog.addNumber("circle size (intensity):", circlesize[aaa], 0, 6, "pixels (size >0!)"); 
			if (Profile==1) {
				Dialog.addNumber("square size (profile):", squaresize[aaa], 0, 6, "pixels (size >0!)"); 
			}
			Dialog.addMessage("Scaling factor: " + x_init + " " + unit_init + "/pixel");
			Dialog.addMessage(circlesize[aaa] + " pixels (circle) = " + x_init*circlesize[aaa] + " " + unit_init);
			if (Profile==1) {
				Dialog.addMessage(squaresize[aaa] + " pixels (square) = " + x_init*squaresize[aaa] + " " + unit_init);
			}
			Dialog.addCheckbox("Preview", true); //Replace with "false" to deactivate preview function by default
			Dialog.show();
			noise[aaa]=Dialog.getNumber();
			smoothsteps[aaa]=Dialog.getNumber();
			circlesize[aaa]=Dialog.getNumber();
			if (Profile==1) {
				squaresize[aaa]=Dialog.getNumber();
			}
			preview=Dialog.getCheckbox();
		} else {
			preview=0;
		}
		if (preview==1) {
			setBatchMode(true); 
			if (isOpen(name_x)) {
				selectImage(name_x);
				close();
			}
			if (isOpen(prev_image)) {
				selectImage(prev_image);
				close();
			}
			roiManager("Reset"); 
			open(Chan1_temp+list1_temp[aaa]);
			prev_image=getTitle(); 
			for (smooth_prev=0; smooth_prev<smoothsteps[aaa]; smooth_prev++) {
				run("Smooth"); 
			}
			roiManager("Open", Output + "/" + name + "/ROIs/ROI_Cell.zip");
			if (cluster==1) {
				if (File.exists(Output + "/" + name + "/ROIs/ROI_Cluster.zip")) {
					roiManager("Reset");
					roiManager("Open", Output + "/" + name + "/ROIs/ROI_Cluster.zip");
					mul_roi=roiManager("Count");
					if (mul_roi>1) {
						mul_Arr=newArray(mul_roi);
						for (n=0; n<mul_roi; n++) {
							mul_Arr[n]=n;
						}
						roiManager("Select", mul_Arr);
						roiManager("OR");
						roiManager("Add");
						roiManager("Delete");
					}
				}
			}
			selectImage(prev_image);
			roiManager("Select", 0);
			run("Find Maxima...", "noise=" + noise[aaa] + " output=List exclude");
			u_prev=nResults;
			x_prev=newArray(u_prev);
			y_prev=newArray(u_prev);
			for (a_prev=0; a_prev<u_prev; a_prev++) {
				x_prev[a_prev]=getResult("X", a_prev);
				y_prev[a_prev]=getResult("Y", a_prev);
			}
			selectWindow("Results");
			run("Close");
			roiManager("Reset");
			roiManager("show all without labels");
			xx_prev=(circlesize[aaa]-1)/2;
			for(b_prev=0; b_prev<u_prev; b_prev++) {
				selectImage(prev_image);
				makeOval(x_prev[b_prev]-xx_prev, y_prev[b_prev]-xx_prev, circlesize[aaa], circlesize[aaa]);
				roiManager("Add");
				roiManager("Select", b_prev);
				roiManager("Set Color", "red"); 
			}
			if (Profile==1) {
				xx_prev=(squaresize[aaa]-1)/2;
				for(b_prev=0; b_prev<u_prev; b_prev++) {
					selectImage(prev_image);
					makeRectangle(x_prev[b_prev]-xx_prev, y_prev[b_prev]-xx_prev, squaresize[aaa], squaresize[aaa]);
					roiManager("Add");
					roiManager("Select", b_prev+u_prev);
					roiManager("Set Color", "blue");
				}
			}
		}
	}
	if (isOpen(name_x)) {
		selectImage(name_x);
		close();
	}
	if (isOpen(prev_image)) {
		selectImage(prev_image);
		close();
	}
	setBatchMode(false); 
}
roiManager("Show None");
run("Input/Output...", "jpeg=85 gif=-1 file=.txt use_file copy_column save_column");
rotation=360; //Replace with the number of rotations of the profile line 
degree=1;	//Replace with the value of degrees for each rotation
setBatchMode(true);
run("Plots...", "interpolate sub-pixel");
run("Text Window...", "name=Progress width=120 height=4 monospaced");
//Identification of podosomes and analysis of the first channel
for (bbb=0; bbb<list1_temp.length; bbb++) {
	if (!endsWith(list1_temp[bbb], "/")) {
		path1=Chan1_temp+list1_temp[bbb];
		open(path1);
		roiManager("Reset");
		name1=getTitle;
		getPixelSize(unit, x_size, y_size);
		bit=bitDepth();
		print("[Progress]", "\\Update:" + "Current image: " + name1 + "\nCurrent channel: " + Channame1 + "\nDone: " + (bbb*Channumber) + "/" + list1_temp.length*Channumber + " (" + ((bbb*Channumber)*100)/(list1_temp.length*Channumber) + "%)");
		selectImage(name1);
		if (bit==8) {
			run("8-bit");
		} else if (bit==16) {
			run("16-bit");
		}
		run("Select None");
		run("Duplicate...", " ");
		duplID=getImageID();
		for (dup=0; dup<smoothsteps[bbb]; dup++) {
			run("Smooth");
		}
		roiManager("Open", Output + "/" + name1 + "/ROIs/ROI_Cell.zip");
		run("Set Measurements...", "area redirect=None decimal=0");
		roiManager("Select", 0);
		roiManager("Measure");
		suma=getResult("Area", 0);
		selectWindow("Results");
		run("Close");
		if (cluster==1) {
			if (File.exists(Output + "/" + name1 + "/ROIs/ROI_Cluster.zip")) {
				roiManager("Reset");
				roiManager("Open", Output + "/" + name1 + "/ROIs/ROI_Cluster.zip");
				mul_roi=roiManager("Count");
				if (mul_roi>1) {
					mul_Arr=newArray(mul_roi);
					for (n=0; n<mul_roi; n++) {
						mul_Arr[n]=n;
					}
					roiManager("Select", mul_Arr);
					roiManager("OR");
					roiManager("Add");
					roiManager("Delete");
				}
			}
		}
		selectImage(duplID);
		roiManager("Select", 0);
		run("Find Maxima...", "noise=" + noise[bbb] + " output=List exclude");
		selectImage(duplID);
		close();
		u=nResults;
		x=newArray(u);
		y=newArray(u);
		for (a=0; a<u; a++) {
			x[a]=getResult("X", a);
			y[a]=getResult("Y", a);
		}
		selectWindow("Results");
		run("Close");
		print("cell area: " + suma + " " + unit + "²");
		print("podosome number: " + u);
		print("noise tolerance: " + noise[bbb]);
		print("smoothing steps: " + smoothsteps[bbb]);
		print("circle size: " + circlesize[bbb]);
		if (Profile==1) {
			print("square size: " + squaresize[bbb]);
			print("rotation steps: " + rotation);
			print("degree per rotation: " + degree); 
		}
		print("scalefactor: " + x_size + " " + unit + "/pixel");
		print("bit depth: " + bit + "-bit");
		if (norm_cell==1) {
			print("normalisation: Yes");
		} else {
			print("normalisation: No");
		}
		selectWindow("Log");
		saveAs("Text", Output + "/" + name1 + "/Parameters.txt");
		selectWindow("Log");
		run("Close");
		roiManager("Reset");
		roiManager("Open", Output + "/" + name1 + "/ROIs/ROI_Cell.zip");
		if (norm_cell==1) {
			selectImage(name1);
			roiManager("Select", 0);
			getStatistics(area, mean, min, max, std, histogram);
			for (aa=0; aa<getWidth; aa++) {
				for (bb=0; bb<getHeight; bb++) {
					value=getPixel(aa,bb);
					if (bit==8) {
						newvalue=((value-min)/(max-min))*255;
					} else if (bit==16) {
						newvalue=((value-min)/(max-min))*65535;
					}
					setPixel(aa,bb,newvalue);
				}
			}
		}
		selectImage(name1);
		roiManager("Select", 0);
		run("Set Measurements...", "integrated redirect=None decimal=0");
		run("Measure");
		sum1=getResult("RawIntDen", 0);
		selectWindow("Results");
		run("Close");
		roiManager("Reset");
		if (bit==8) {
			newImage(Channame1, "8-bit black", circlesize[bbb], circlesize[bbb], u);
		} else if (bit==16) {
			newImage(Channame1, "16-bit black", circlesize[bbb], circlesize[bbb], u);
		}
		xx=(circlesize[bbb]-1)/2;
		roiManager("Show None");
		for(b=0; b<u; b++) {
			selectImage(name1);
			makeOval(x[b]-xx, y[b]-xx, circlesize[bbb], circlesize[bbb]);
			roiManager("Add");
			selectImage(name1);
			roiManager("Select", b);
			run("Copy");
			selectImage(Channame1);
			setSlice(b+1);
			run("Paste");
		}
		resArray=newArray(u);
		selectImage(Channame1);
		run("Select None");
		for (c=1; c<=u; c++) {
			selectImage(Channame1);
			setSlice(c);
			run("Measure");
			resArray[c-1]=getResult("RawIntDen",c-1);
		}
		selectWindow("Results");
		run("Close");
		File.makeDirectory(Output + "/" + name1 + "/Images");
		selectImage(Channame1);
		if (norm_cell==0) {
			saveAs("Tiff",  Output + "/" + name1 + "/Images/Podosomestack " + Channame1 + ".tiff");
		} else {
			saveAs("Tiff",  Output + "/" + name1 + "/Images/Podosomestack " + Channame1 + " normalised.tiff");
		}
		close();
		roiManager("Save", Output + "/" + name1 + "/ROIs/ROIs_Podosomes.zip");
		//Combining of podosome ROIs and analysis of size and intensity 
		PodArray=newArray(u);
		for (d=0; d<u; d++) {
			PodArray[d]=d;
		}
		roiManager("Select", PodArray);
		roiManager("Combine");
		roiManager("Update"); 
		roiManager("Deselect");
		PodArray2=Array.slice(PodArray,1);
		roiManager("Select", PodArray2);
		roiManager("Delete");
		roiManager("Select", 0);
		Roi.getBounds(x_combine, y_combine, width_combine, height_combine);
		if (bit==8) {
			newImage(Channame1 + "_combined", "8-bit black", width_combine, height_combine, 1);
		} else if (bit==16) {
			newImage(Channame1 + "_combined", "16-bit black", width_combine, height_combine, 1);
		}
		selectImage(name1);
		roiManager("Select", 0);
		run("Copy");
		selectImage(Channame1 + "_combined");
		run("Paste");
		run("Set Measurements...", "area redirect=None decimal=0");
		selectImage(name1);
		roiManager("Select", 0);
		run("Measure");
		sumb=getResult("Area", 0);
		selectWindow("Results");
		run("Close");
		run("Set Measurements...", "integrated redirect=None decimal=0");
		selectImage(Channame1 + "_combined");
		run("Select None");
		run("Measure");
		sum2=getResult("RawIntDen",0);
		selectImage(Channame1 + "_combined");
		if (data_save=="all") {
			if (norm_cell==0) {
				saveAs("Tiff",  Output + "/" + name1 + "/Images/Podosome covered area " + Channame1 + ".tiff");
			} else {
				saveAs("Tiff",  Output + "/" + name1 + "/Images/Podosome covered area " + Channame1 + " normalised.tiff");
			}
		}
		close();
		roiManager("Save", Output + "/" + name1 + "/ROIs/ROIs_Podosomes_combined.zip");
		selectWindow("Results");
		run("Close");
		roiManager("Reset");
		//Profile analysis
		if (Profile==1) {
			File.makeDirectory(Output + "/" + name1 + "/Profiles");
			File.makeDirectory(Output + "/" + name1 + "/Profiles/Images");
			if (data_save=="all") {
				File.makeDirectory(Output + "/" + name1 + "/Profiles/Single rotations");
			}
			if (bit==8) {
				newImage("Profname", "8-bit black", squaresize[bbb], squaresize[bbb], u);
			} else if (bit==16) {
				newImage("Profname", "16-bit black", squaresize[bbb], squaresize[bbb], u);
			}
			xy=(squaresize[bbb]-1)/2;
			for(e=0; e<u; e++) {
				selectImage(name1);
				makeRectangle(x[e]-xy, y[e]-xy, squaresize[bbb], squaresize[bbb]);
				roiManager("Add");
				selectImage(name1);
				roiManager("Select", e);
				run("Copy");
				selectImage("Profname");
				setSlice(e+1);
				run("Paste");
			}
			if (single_profiles==1) {
				File.makeDirectory(Output + "/" + name1 + "/Profiles/Individual profiles");
				if (data_save=="all") {
					File.makeDirectory(Output + "/" + name1 + "/Profiles/Individual profiles/Single rotations");
				}
				do_single_profiles(Channame1, "original");
			}
			do_profile(Channame1, "original", 0);
			close();
			selectImage("Profname");
			if (data_save=="all") {
				run("Duplicate...", "duplicate");
				if (norm_cell==0) {
					saveAs("Tiff",  Output + "/" + name1 + "/Images/Profilestack " + Channame1 + ".tiff");
				} else {
					saveAs("Tiff",  Output + "/" + name1 + "/Images/Profilestack " + Channame1 + " normalised.tiff");
				}
				close();
			}
			for (f=1; f<=u; f++) {
				selectImage("Profname");
				setSlice(f);
				getStatistics(area, mean, min, max, std, histogram);
				for (aax=0; aax<getWidth; aax++) {
					for (bbx=0; bbx<getHeight; bbx++) {
						value=getPixel(aax,bbx);
						if (bit==8) {
							newvalue=((value-min)/(max-min))*255;
						} else if (bit==16) {
							newvalue=((value-min)/(max-min))*65535;
						}
						setPixel(aax,bbx,newvalue);
					}
				}
			}
			if (single_profiles==1) {
				do_single_profiles(Channame1, "stack normed");
			}
			do_profile(Channame1, "stack normed", 0);
			getStatistics(area, mean, min, max, std, histogram);
			for (aax=0; aax<getWidth; aax++) {
				for (bbx=0; bbx<getHeight; bbx++) {
					value=getPixel(aax,bbx);
					if (bit==8) {
						newvalue=((value-min)/(max-min))*255;
					} else if (bit==16) {
						newvalue=((value-min)/(max-min))*65535;
					}
					setPixel(aax,bbx,newvalue);
				}
			}
			do_profile(Channame1, "z-projection and stack normed", 1);
			close();
			selectImage("Profname");
			if (data_save=="all") {
				if (norm_cell==0) {
					saveAs("Tiff",  Output + "/" + name1 + "/Images/Profilestack " + Channame1 + " (normed).tiff");
				} else {
					saveAs("Tiff",  Output + "/" + name1 + "/Images/Profilestack " + Channame1 + " (normed) and normalised.tiff");
				}
			}
			close();
			roiManager("Save", Output + "/" + name1 + "/ROIs/ROIs_Podosomes_Profiles.zip");
			roiManager("Reset");
		}
		roiManager("Open", Output + "/" + name1 + "/ROIs/ROI_Cell.zip");
		selectImage(name1);
		roiManager("Select", 0); 
		run("Copy"); 
		Roi.getBounds(x_Cell, y_Cell, width_Cell, height_Cell); 
		if (bit==8) {
			newImage("Cell", "8-bit black", width_Cell, height_Cell, 1);
		} else if (bit==16) {
			newImage("Cell", "16-bit black", width_Cell, height_Cell, 1);
		}
		selectImage("Cell");
		run("Paste");
		run("Select None");
		if (norm_cell==0) {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Cell " + Channame1 + ".tiff");
		} else {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Cell " + Channame1 + " normalised.tiff");
		}
		close();
		selectImage(name1);
		run("Select None"); 
		if (norm_cell==0) {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Source image " + Channame1 + ".tiff");
		} else {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Source image " + Channame1 + " normalised.tiff");
		}
		close();
		roiManager("Reset"); 
		//Saving of results in one big table
		if (bbb!=0) {
			IJ.renameResults(Channame1, "Results");
		}
		Cell_name=substring(name1, 0, lengthOf(name1)-5);
		setResult(Cell_name, 0, "cellsize [" + unit + "²]:");
		setResult(Cell_name, 1, suma);
		setResult(Cell_name, 2, "intensity cell area:");
		setResult(Cell_name, 3, sum1);
		setResult(Cell_name, 4, "size podosome-covered area [" + unit + "²]:");
		setResult(Cell_name, 5, sumb);
		setResult(Cell_name, 6, "intensity podosome-covered area:");
		setResult(Cell_name, 7, sum2);
		setResult(Cell_name, 8, "single values " + Channame1);
		for (res=0; res<u; res++) {
			setResult(Cell_name, res+9, resArray[res]);
		}
		updateResults;
		IJ.renameResults("Results", Channame1);
	}
	if (Channumber>1) {
		count=1;
		Analysis(list2_temp, Chan2_temp, Channame2);
		if (Channumber>2) {
			count=2;
			Analysis(list3_temp, Chan3_temp, Channame3);
			if (Channumber>3) {
				count=3;
				Analysis(list4_temp, Chan4_temp, Channame4);
			}
		}
	}
	//Saving of profile results
	if (Profile==1) {
		run("Set Measurements...", "integrated redirect=None decimal=" + decimal);
		IJ.renameResults("Prof_original", "Results");
		selectWindow("Results"); 
		saveAs("Results", Output + "/" + name1 + "/Profiles/Profiles (original)" + data_ending);
		run("Close");
 		IJ.renameResults("Prof_stack normed", "Results");
		selectWindow("Results"); 
		saveAs("Results", Output + "/" + name1 + "/Profiles/Profiles (stack normed)" + data_ending);
		run("Close");
		IJ.renameResults("Prof_z-projection and stack normed", "Results");
		selectWindow("Results"); 
		saveAs("Results", Output + "/" + name1 + "/Profiles/Profiles (z-projection and stack normed)" + data_ending);
		run("Close");
		IJ.renameResults("Prof_stDev_original", "Results");
		selectWindow("Results");
		if (data_save=="all") {
			saveAs("Results", Output + "/" + name1 + "/Profiles/Single rotations/Mean with stDev of single rotations (original)" + data_ending);
		}
		run("Close");
		IJ.renameResults("Prof_stDev_stack normed", "Results");
		selectWindow("Results");
		if (data_save=="all") {
			saveAs("Results", Output + "/" + name1 + "/Profiles/Single rotations/Mean with stDev of single rotations (stack normed)" + data_ending);
		}
		run("Close");
		IJ.renameResults("Prof_stDev_z-projection and stack normed", "Results");
		selectWindow("Results");
		if (data_save=="all") {
			saveAs("Results", Output + "/" + name1 + "/Profiles/Single rotations/Mean with stDev of single rotations (z-projection and stack normed)" + data_ending);
		}
		run("Close");
		if (single_profiles==1) {
			IJ.renameResults("Single profs_original", "Results");
			selectWindow("Results"); 
			saveAs("Results", Output + "/" + name1 + "/Profiles/Individual profiles/Mean with stDev of individual profiles (original)" + data_ending);
			run("Close");
			IJ.renameResults("Single profs_stack normed", "Results");
			selectWindow("Results"); 
			saveAs("Results", Output + "/" + name1 + "/Profiles/Individual profiles/Mean with stDev of individual profiles (stack normed)" + data_ending);
			run("Close");
		}
		run("Set Measurements...", "integrated redirect=None decimal=0");
	}
	File.rename(Output + "/" + name1, Output + "/" + Cell_name);
	selectWindow("Log");
	run("Close");
}
for (xxx=0; xxx<list1_temp.length; xxx++) {
	File.delete(Chan1_temp + list1_temp[xxx]);
	if (Channumber>1) {
		File.delete(Chan2_temp + list2_temp[xxx]);
		if (Channumber>2) {
			File.delete(Chan3_temp + list3_temp[xxx]);
			if (Channumber>3) {
				File.delete(Chan4_temp + list4_temp[xxx]);
			}
		}
	}
}
selectWindow(Channame1);
saveAs("Results", Output + "//Results_" + Channame1 + data_ending);
run("Close");
File.delete(Chan1_temp);
if (Channumber>1) {
	selectWindow(Channame2);
	saveAs("Results", Output + "//Results_" + Channame2 + data_ending);
	run("Close");
	File.delete(Chan2_temp);
	if (Channumber>2) {
		selectWindow(Channame3);
		saveAs("Results", Output + "//Results_" + Channame3 + data_ending);
		run("Close");
		File.delete(Chan3_temp);
		if (Channumber>3) {
			selectWindow(Channame4);
			saveAs("Results", Output + "//Results_" + Channame4 + data_ending);
			run("Close");
			File.delete(Chan4_temp);
		}
	}
}
selectWindow("Log");
run("Close");
setBatchMode(false);
selectWindow("ROI Manager");
run("Close");
print("[Progress]", "\\Close");
//Definition of function 1 - Analysis of every other channel apart from the first channel; no podosome identification (uses postitions from channel 1).
function Analysis(source1, source2, protein) {	
	if (!endsWith(source1[bbb], "/")) {
		path2=source2+source1[bbb];
		open(path2);
		name2=getTitle;
		print("[Progress]", "\\Update:" + "Current image: " + name2 + "\nCurrent channel: " + protein + "\nDone: " + ((bbb*Channumber) + count) + "/" + list1_temp.length*Channumber + " (" + (((bbb*Channumber)+count)*100)/(list1_temp.length*Channumber) + "%)");
		selectImage(name2);
		if (bit==8) {
			run("8-bit");
		} else if (bit==16) {
			run("16-bit");
		}
		roiManager("Open", Output + "/" + name1 + "/ROIs/ROI_Cell.zip");
		if (norm_cell==1) {
			roiManager("Select", 0);
			getStatistics(area, mean, min, max, std, histogram);
			for (aa=0; aa<getWidth; aa++) {
				for (bb=0; bb<getHeight; bb++) {
					value=getPixel(aa,bb);
					if (bit==8) {
						newvalue=((value-min)/(max-min))*255;
					} else if (bit==16) {
						newvalue=((value-min)/(max-min))*65535;
					}
					setPixel(aa,bb,newvalue);
				}
			}
		}
		selectImage(name2);
		roiManager("Select", 0);
		run("Measure");
		sum3=getResult("RawIntDen",0);
		selectWindow("Results");
		run("Close");
		roiManager("Reset");
		roiManager("Open", Output + "/" + name1 + "/ROIs/ROIs_Podosomes.zip");
		if (bit==8) {
			newImage(protein, "8-bit black", circlesize[bbb], circlesize[bbb], u);
		} else if (bit==16) {
			newImage(protein, "16-bit black", circlesize[bbb], circlesize[bbb], u);
		}
		for (g=0; g<u; g++) {
			selectImage(name2);
			roiManager("Select", g);
			run("Copy");
			selectImage(protein);
			setSlice(g+1);
			run("Paste");
		}
		resArray=newArray(u);
		selectImage(protein);
		run("Select None");
		for (h=1; h<=u; h++) {
			selectImage(protein);
			setSlice(h);
			run("Measure");
			resArray[h-1]=getResult("RawIntDen",h-1);
		}
		selectWindow("Results");
		run("Close");
		selectImage(protein);
		if (norm_cell==0) {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Podosomestack " + protein + ".tiff");
		} else {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Podosomestack " + protein + " normalised.tiff");
		}
		close();
		roiManager("Reset");
		//Analysis of size and intensity of combined podosome ROI
		roiManager("Open", Output + "/" + name1 + "/ROIs/ROIs_Podosomes_combined.zip");
		if (bit==8) {
			newImage(protein + "_combined", "8-bit black", width_combine , height_combine, 1);
		} else if (bit==16) {
			newImage(protein + "_combined", "16-bit black", width_combine , height_combine, 1);
		}
		selectImage(name2);
		roiManager("Select", 0);
		run("Copy");
		selectImage(protein + "_combined");
		run("Paste");
		selectImage(protein + "_combined");
		run("Select None");
		run("Measure");
		sum4=getResult("RawIntDen",0);
		selectImage(protein + "_combined");
		if (data_save=="all") {
			if (norm_cell==0) {
				saveAs("Tiff", Output + "/" + name1 + "/Images/Podosome covered area " + protein + ".tiff");
			} else {
				saveAs("Tiff", Output + "/" + name1 + "/Images/Podosome covered area " + protein + " normalised.tiff");
			}
		}
		close();
		selectWindow("Results");
		run("Close");
		roiManager("Reset");
		//Profile analysis
		if (Profile==1) { 
			roiManager("Open", Output + "/" + name1 + "/ROIs/ROIs_Podosomes_Profiles.zip");
			if (bit==8) {
				newImage("Profname", "8-bit black", squaresize[bbb], squaresize[bbb], u);
			} else if (bit==16) {
				newImage("Profname", "16-bit black", squaresize[bbb], squaresize[bbb], u);
			}
			for (i=0; i<u; i++) {
				selectImage(name2);
				roiManager("Select", i);
				run("Copy");
				selectImage("Profname");
				setSlice(i+1);
				run("Paste");
			}
			if (single_profiles==1) {
				do_single_profiles(protein, "original");
			}
			do_profile(protein, "original", 0); 
			close(); 
			selectImage("Profname");
			if (data_save=="all") {
				run("Duplicate...", "duplicate");
				if (norm_cell==0) {
					saveAs("Tiff",  Output + "/" + name1 + "/Images/Profilestack " + protein + ".tiff");
				} else {
					saveAs("Tiff",  Output + "/" + name1 + "/Images/Profilestack " + protein + " normalised.tiff");
				}
				close();
			}
			for (j=1; j<=u; j++) {
				selectImage("Profname");
				setSlice(j);
				getStatistics(area, mean, min, max, std, histogram);
				for (aax=0; aax<getWidth; aax++) {
					for (bbx=0; bbx<getHeight; bbx++) {
						value=getPixel(aax,bbx);
						if (bit==8) {
							newvalue=((value-min)/(max-min))*255;
						} else if (bit==16) {
							newvalue=((value-min)/(max-min))*65535;
						}
						setPixel(aax,bbx,newvalue);
					}
				}
			}
			if (single_profiles==1) {
				do_single_profiles(protein, "stack normed");
			}
			do_profile(protein, "stack normed", 0);
			getStatistics(area, mean, min, max, std, histogram);
			for (aax=0; aax<getWidth; aax++) {
				for (bbx=0; bbx<getHeight; bbx++) {
					value=getPixel(aax,bbx);
					if (bit==8) {
						newvalue=((value-min)/(max-min))*255;
					} else if (bit==16) {
						newvalue=((value-min)/(max-min))*65535;
					}
					setPixel(aax,bbx,newvalue);
				}
			}
			do_profile(protein, "z-projection and stack normed", 1);
			close();
			selectImage("Profname");
			if (data_save=="all") {
				if (norm_cell==0) {
				saveAs("Tiff",  Output + "/" + name1 + "/Images/Profilestack " + protein + " (normed).tiff");
				} else {
					saveAs("Tiff",  Output + "/" + name1 + "/Images/Profilestack " + protein + " (normed) and normalised.tiff");
				}
			}
			close();
			roiManager("Reset");
		}
		roiManager("Open", Output + "/" + name1 + "/ROIs/ROI_Cell.zip");
		selectImage(name2);
		roiManager("Select", 0);
		run("Copy");
		if (bit==8) {
			newImage("Cell", "8-bit black", width_Cell, height_Cell, 1); 
		} else if (bit==16) {
			newImage("Cell", "16-bit black", width_Cell, height_Cell, 1); 
		}
		selectImage("Cell");
		run("Paste"); 
		run("Select None");
		if (norm_cell==0) {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Cell " + protein + ".tiff");
		} else {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Cell " + protein + " normalised.tiff");
		}
		close();
		selectImage(name2);
		run("Select None"); 
		if (norm_cell==0) {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Source image " + protein + ".tiff");
		} else {
			saveAs("Tiff", Output + "/" + name1 + "/Images/Source image " + protein + " normalised.tiff");
		}
		close(); 
		roiManager("Reset"); 
		//Save results in one big table per channel
		if (bbb!=0) {
			IJ.renameResults(protein, "Results");
		}
		setResult(Cell_name, 0, "cellsize [" + unit + "²]:");
		setResult(Cell_name, 1, suma);
		setResult(Cell_name, 2, "intensity cell area:");
		setResult(Cell_name, 3, sum3);
		setResult(Cell_name, 4, "size podosome-covered area [" + unit + "²]:");
		setResult(Cell_name, 5, sumb);
		setResult(Cell_name, 6, "intensity podosome-covered area:");
		setResult(Cell_name, 7, sum4);
		setResult(Cell_name, 8, "single values " + protein);
		for (res=0; res<u; res++) {
			setResult(Cell_name, res+9, resArray[res]);
		}
		updateResults;
		IJ.renameResults("Results", protein);
	}
}
//Definition of function 2 - Additional analysis of single podosomes
function do_single_profiles(channel_name, norm_status) {
	run("Set Measurements...", "integrated redirect=None decimal=" + decimal);
	selectImage("Profname");
	n_single=nSlices;
	width_single=getWidth();
	y_single=(width_single-1)/2;
	slices_single=newArray(width_single*n_single);
	stDev_single=newArray(width_single*n_single);
	for (a_single=1; a_single<=n_single; a_single++) {
		selectImage("Profname");
		setSlice(a_single);
		for(k_single=0; k_single<rotation; k_single++) {
			selectImage("Profname");
			makeLine(0, y_single, width_single-1, y_single);
			run("Rotate...", "angle="+k_single*degree);
			profile=getProfile();
			for (kk_single=0; kk_single<profile.length; kk_single++) {
				setResult("Rotation " + k_single, kk_single, profile[kk_single]);
			}
		}
		updateResults();
		results_temp=newArray(rotation);
		for (m_single=0; m_single<width_single; m_single++) {
			for (mm_single=0; mm_single<rotation; mm_single++) {
				results_temp[mm_single]=getResult("Rotation " + mm_single, m_single);
			}
			Array.getStatistics(results_temp, min_sing, max_sing, mean_sing, stDev_sing);
			slices_single[(width_single*(a_single-1))+m_single]=mean_sing;
			if (isNaN(stDev_sing)==1) {
				stDev_single[(width_single*(a_single-1))+m_single]=0;
			} else {
				stDev_single[(width_single*(a_single-1))+m_single]=stDev_sing;
			}
		}
		selectWindow("Results"); 
		if (data_save=="all") {
			saveAs("Results", Output + "/" + name1 + "/Profiles/Individual profiles/Single rotations/Podosome " + a_single + " " + channel_name + " (" + norm_status + ")" + data_ending);
		} 			
	}
	run("Close");
	if (data_save=="all") {
		for (sa=0; sa<n_single; sa++) {
			for (sb=0; sb<width_single; sb++) {
				setResult("Podosome " + sa + 1, sb, slices_single[(width_single*sa)+sb]);
				setResult("Slice " + sa + 1, sb, stDev_single[(width_single*sa)+sb]);
			}
		}
		updateResults();
		selectWindow("Results");
		saveAs("Results", Output + "/" + name1 + "/Profiles/Individual profiles/Single rotations/Mean with stDev of single rotations " + channel_name + " (" + norm_status + ")" + data_ending);
		run("Close");
	}
	for (sa=0; sa<n_single; sa++) {
		for (sb=0; sb<width_single; sb++) {
			setResult("Podosome " + sa + 1, sb, slices_single[(width_single*sa)+sb]);
		}
	}
	updateResults(); 
	single_results=newArray(n_single);
	means=newArray(width_single);
	stDevs=newArray(width_single);
	for (o_single=0; o_single<width_single; o_single++) {
		for (m_single=0; m_single<n_single; m_single++) {
			single_results[m_single]=getResult("Podosome " + m_single+1, o_single);
		}
		Array.getStatistics(single_results, min_sr, max_sr, mean_sr, stDev_sr);
		means[o_single]=mean_sr;
		stDevs[o_single]=stDev_sr;
	}
	selectWindow("Results");
	saveAs("Results", Output + "/" + name1 + "/Profiles/Individual profiles/Individual profiles " + channel_name + " (" + norm_status + ")" + data_ending);
	run("Close");
	if (channel_name!=Channame1) {
		IJ.renameResults("Single profs_" + norm_status, "Results"); 
	}
	for (g_single=0; g_single<width_single; g_single++) {
		setResult("Mean " + channel_name, g_single, means[g_single]);
		setResult("stDev " + channel_name, g_single, stDevs[g_single]);
	}
	updateResults;
	selectWindow("Results");
	IJ.renameResults("Results", "Single profs_" + norm_status); 
	run("Set Measurements...", "integrated redirect=None decimal=0");
	selectImage("Profname");
	run("Select None");
	setSlice(1);
}
//Definition of function 3 - Profile analysis
function do_profile(iname, def, dont_select) {
	run("Set Measurements...", "integrated redirect=None decimal=" + decimal);
	if (dont_select!=1) {
		selectImage("Profname");
		run("Z Project...", "projection=[Average Intensity]");
	}
	podavg=getTitle();
	y_avg=(getWidth-1)/2;
	width_avg=getWidth;
	for(k=0; k<rotation; k++) {
		selectImage(podavg);
		makeLine(0, y_avg, width_avg-1, y_avg);
		run("Rotate...", "angle=" + k*degree);
		profile=getProfile();
		for (kk=0; kk<profile.length; kk++) {
			setResult("Rotation " + k, kk, profile[kk]);
		}
	}
	updateResults;
	results=newArray(rotation); 
	prof_values=newArray(width_avg);
	stDevs=newArray(width_avg);
	for (m=0; m<width_avg; m++) {
		for (mm=0; mm<rotation; mm++) {
			results[mm]=getResult("Rotation " + mm, m);
		}
		Array.getStatistics(results, min_prof, max_prof, mean_prof, stDev_prof);
		prof_values[m]=mean_prof;
		if (isNaN(stDev_prof)==1) {
			stDevs[m]=0;
		} else {
		stDevs[m]=stDev_prof;
		}
	}
	selectWindow("Results");
	if (data_save=="all") {
		saveAs("Results", Output + "/" + name1 + "/Profiles/Single rotations/Single rotations " + iname + " (" + def + ")" + data_ending);
	}
	run("Close");
	run("Set Measurements...", "integrated redirect=None decimal=0");
	if (iname!=Channame1) {
		IJ.renameResults("Prof_" + def, "Results"); 
	}
	for (m=0; m<width_avg; m++) {
		setResult(iname, m, prof_values[m]);
	}
	updateResults;
	IJ.renameResults("Results", "Prof_" + def);
	if (iname!=Channame1) {
		IJ.renameResults("Prof_stDev_" + def, "Results"); 
	}
	for (m=0; m<width_avg; m++) {
		setResult(iname, m, prof_values[m]);
		setResult(iname + "_stDev", m, stDevs[m]);
	}
	updateResults;
	IJ.renameResults("Results", "Prof_stDev_" + def); 
	selectImage(podavg);
	saveAs("Tiff", Output + "/" + name1 + "/Profiles/Images/Z-projection " + iname + " (" + def + ").tiff");
}