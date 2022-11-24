
/*This macro is related to the publication "Poji: a Fiji-based tool for analysis of podosomes and associated proteins" in Journal of Cell Science by Herzog et al. 2020, doi: 10.1242/jcs.238964. For concept of proof, please refer to the linked publication.
Macro, userguide and associated Excel tables are available online at https://github.com/roherzog/Poji and at http://www.linderlab.de/tools. For further advices on using the macro and associated tables, please refer to the userguide.
If you publish data that were obtained by using this macro, please cite the original publication accordingly!
@ Author: Robert Herzog, 2020-2022
*/


//Initial step 1 - Selection of Channels and Names

//Definition of channels names trough an array, looping through number of input images, automatic detection if images are multichannel or single channel.
//If they are multichannel, the array is activated, if they are single channels, the user is asked to add additional channels (compatability with older version)
fs=File.separator;
chan_names=newArray("F-actin", "Vinculin", "MyosinIIA", "LSP1"); //Change names and order of the channels
single_origins=newArray(4);
multichannel=0;
for (init=0; init<chan_names.length; init++) {
	origin=getDirectory("Please choose the directory of your images"); 
	origin_list=getFileList(origin);
	for (check=0; check<origin_list.length; check++) {
		if (File.isDirectory(origin+origin_list[check])) {
			boo=getBoolean("There seem to be folders in your input directory. Do you want to proceed the analysis? \nPress 'Yes' to proceed (danger of macro errors). \nPress 'No' to interrupt the analysis."); 
			if (boo==0) {
				exit("Please restart the macro after making sure, you only have image files in your input folder");
			}
		}
	}
	open(origin+origin_list[0]);
	title_init=getTitle(); 
	getDimensions(width_init, height_init, Channumber, slices_init, frames_init);
	if (Channumber>1) {
		multichannel=1;
		for (ch=0; ch<Channumber; ch++) {
			Stack.setChannel(ch+1); 
			Dialog.create("Define channel names");
			Dialog.addMessage("Please define the name of the active channel.");
			Dialog.addString("Channel name:", chan_names[ch]); 
			Dialog.show;
			chan_names[ch]=replace(Dialog.getString(), " ", "_");
		}
		init=chan_names.length-1;
	} else {
		Chan_counter+=1;
		Dialog.create("Define channel names");
		if (init==0) {
			Dialog.addMessage("Podosome will be detected in this channel");
		}
		Dialog.addMessage("Please define the name of this channel"); 
		Dialog.addString("Channel name: " + init+1, chan_names[init]);
		if (init<chan_names.length-1) {
			Dialog.addCheckbox("Add another channel?", true); 
		}
		Dialog.show(); 
		chan_names[init]=replace(Dialog.getString(), " ", "_");
		if (init<chan_names.length-1) {
			add_channel=Dialog.getCheckbox();
		} else {
			add_channel=0;
		}
		single_origins[init]=origin;
		if (add_channel==0) {
			init=chan_names.length-1;
			Channumber=Chan_counter;
		}
	}
	selectImage(title_init); 
	close();
}

//If images are not multichannel, the combined origin input is replaced by the respective input folders of the single channels (important for ROI annotation)
//The fist channel in this case has to be the one of podosome detection
if (multichannel==0) {
	origin=single_origins[0];
	origin_list=getFileList(origin);
	for (li=0; li<Channumber; li++) {
		if (li==0) {
			list_channels_0=getFileList(single_origins[li]);
		} else if (li==1) {
			list_channels_1=getFileList(single_origins[li]);
		} else if (li==2) {
			list_channels_2=getFileList(single_origins[li]);
		} else if (li==3) {
			list_channels_3=getFileList(single_origins[li]);
		}
	}
}

//Creation of temporary input paths (where the temp images are saved after ROI selection and where they are called from in the actual analysis)
//Also creation of the output folder, with failsafe in case there already is data present in it (danger of overwriting)
chan_names=Array.slice(chan_names, 0, Channumber);
chan_directories=newArray(Channumber);
temp_directory=origin + "Reference_temp" + fs;
File.makeDirectory(temp_directory);
for (tf=0; tf<chan_names.length; tf++) {
	if (multichannel==1) {
		chan_directories[tf]=origin + chan_names[tf] + "_temp" + fs;
	} else {
		chan_directories[tf]=single_origins[tf] + chan_names[tf] + "_temp" + fs;
	}
	File.makeDirectory(chan_directories[tf]);
}
Output=getDirectory("Select output folder for the results");
file_out=getFileList(Output);
if (file_out.length>0) {
	boo=getBoolean("There seems to be data in your results folder. Do you want to proceed the analysis? \nPress 'Yes' to proceed (danger of overwriting and macro errors). \nPress 'No' to interrupt the analysis."); 
	if (boo==0) {
		for (err=0; err<Channumber; err++) {
			File.delete(chan_directories[err]);
		}
		File.delete(temp_directory);
		selectWindow("Log");
		run("Close");
		exit("Please restart the macro again after clearing the results folder");
	}
}

//Initial Step 2 - Selection of Analysis parameters

//UI for (de-)activating analysis- detection, and data handling options. Order and default state of the options can be changed by user
Dialog.create("Choose analysis and data saving options"); //Change "true" for "false" or vice versa to (de-)activate checkboxes by default
Dialog.addMessage("General analysis options"); 
Dialog.addCheckbox("normalise fluorescence intensity in cell area?", false);
Dialog.addCheckbox("additionally select podosome clusters?", true);
Dialog.addCheckbox("identical cell and cluster areas for all images?", false);
Dialog.addCheckbox("identical detection conditions for all images?", false);
Dialog.addCheckbox("calculate average profiles?", true);
Dialog.addCheckbox("also calculate individual profiles? (very slow!)", false);
Dialog.addMessage("Data saving options");
Dialog.addChoice("stack comparison method:", newArray("Automatically detect z=0", "User defined slice is z=0", "None")); //Set preferred option to first position to select it by default
Dialog.addNumber("decimals in profile results:", 3); //Change "3" for preferred number of decimals (max. 9)
Dialog.addChoice("data format for result tables:", newArray(".tsv", ".txt", ".csv")); //Set the preferred ending to the first position to select it by default 
Dialog.addChoice("save data from analysis:", newArray("essential data", "+ overview images", "+ extended data")); //Set preferred option to first position to select it by default
Dialog.show();
norm_cell=Dialog.getCheckbox();
cluster=Dialog.getCheckbox();
same_ROI=Dialog.getCheckbox();
same_detec=Dialog.getCheckbox();
profile=Dialog.getCheckbox();
single_profiles=Dialog.getCheckbox();
res_auto_sort=Dialog.getChoice();
decimal=Dialog.getNumber();
data_ending=Dialog.getChoice();
data_save=Dialog.getChoice();
if (profile==false && res_auto_sort=="Automatically detect z=0") {
	res_auto_sort="User defined slice is z=0";
	waitForUser("Your results comparison method has been changed to 'User defined slice is z=0'\nbecause automatic detection is only possible with activated profile comparison"); 
} 
if (profile==1) {
	Dialog.create("Profile options");
	Dialog.addMessage("Define options for profile analysis"); 
	Dialog.addNumber("Number of rotation steps:", 360); //Replace with the number of rotations of the profile line 
	Dialog.addNumber("Degree per rotation steps:", 1); //Replace with the value of degrees for each rotation
	Dialog.show();
	rotation=Dialog.getNumber(); 
	degree=Dialog.getNumber();	
}

//Initial Step 3 - Selection and saving of ROIs per cell and creation of temporary image files (multiple times if multiple cells are selected on one image) 

//In the first part, the origi is called (input folder for multichannel images or input folder of first channel for single channel images)
//Selection of ROIs around cells and detection of general dimensions (scale, channels, slices, number of cells) per image
slices_per_image=newArray(0);
selected_slice_per_image=newArray(0); 
selected_channel_per_image=newArray(0);
x_size=newArray(0);
z_size=newArray(0);
unit=newArray(0);
for (aaa=0; aaa<origin_list.length; aaa++) {
	if (!File.isDirectory(origin+origin_list[aaa])) {
		path1=origin+origin_list[aaa];
		setBatchMode(false);
		open(path1);
		name_a=getTitle();
		name_a2=replace(File.nameWithoutExtension, " ", "_");;
		getDimensions(width_a, height_a, channels_a, slices_a, frames_a);
		bit=bitDepth();
		if (bit!=8 && bit!=16) {
			showMessage("Macro stopped!", "Only 8- and 16-bit images supported! \nPlease adjust your images accordingly. \nPlease delete the 'Analysis_temp' folders that appeared \nin your source folder before you restart the macro.");
			run("Close All");
			exit();
		}
		if (same_ROI==0 || aaa==0) {
			roiManager("Reset");
			while (roiManager("Count")==0) {
				waitForUser("Select Cell Area(s)", "Please set the correct channel and slice for podosome detection (if (hyper-)stack).\nPlease select a ROI around the cell(s) and add it/them to the ROI manager (press 't').\nYou can select several cells on different planes.\nPress 'OK' to proceed after all cells are selected."); 
			}
		}
		setBatchMode(true);
		nRois=roiManager("Count");
		sspi=newArray(nRois); //selected slice per image, just for creation of temporary files, is overwritten when new images is opened
		scpi=newArray(nRois); //selected channel per image, see above
		for (ar_int=0; ar_int<nRois; ar_int++) {
			if (channels_a>1 || slices_a>1) {
				selectImage(name_a);
				roiManager("Select", ar_int); 
				Stack.getPosition(channel_b, slice_b, frame_b);
				sspi[ar_int]=slice_b;
				scpi[ar_int]=channel_b;
				slices_per_image=Array.concat(slices_per_image, slices_a); //general value that is carried over to the analysis part and is thus expanded for every opened image
				selected_slice_per_image=Array.concat(selected_slice_per_image, slice_b); //see above
				selected_channel_per_image=Array.concat(selected_channel_per_image, channel_b); //see above
			} else {
				sspi[ar_int]=0;
				scpi[ar_int]=0;
				slices_per_image=Array.concat(slices_per_image, slices_a);
				selected_slice_per_image=Array.concat(selected_slice_per_image, 0);
				selected_channel_per_image=Array.concat(selected_channel_per_image, 0);
			}
			getVoxelSize(x_sizes, y_sizes, z_sizes, units);
			x_size=Array.concat(x_size, x_sizes);
			z_size=Array.concat(z_size, z_sizes);
			unit=Array.concat(unit, units);
		}
		selectImage(name_a);
		close();

		//Crearion of temporary single-slice, single-channel images based on channel and slice of user-based ROI-selection; these temporary files are later called for podosome detection; 1 reference image for each hyperstack
		for (abc=1; abc<=nRois; abc++) {
			if (nRois>1) {
				File.makeDirectory(Output + name_a2 + "_Cell_" + abc + ".tiff");
				File.makeDirectory(Output + name_a2 + "_Cell_" + abc + ".tiff" + fs + "ROIs");
				roiManager("Select", abc-1);
				roiManager("Save", Output + name_a2 + "_Cell_" + abc + ".tiff" + fs + "ROIs" + fs + "ROI_Cell.roi");
				open(path1);
				if (channels_a>1 || slices_a>1) {
					Stack.setSlice(sspi[abc-1]);
					Stack.setChannel(scpi[abc-1]);
					run("Duplicate...", " ");
					selectImage(name_a);
					close(); 
				}
				saveAs("Tiff", temp_directory + name_a2 + "_Cell_" + abc + ".tiff");
			} else {
				File.makeDirectory(Output + name_a2 + ".tiff");
				File.makeDirectory(Output + name_a2 + ".tiff" + fs + "ROIs");
				roiManager("Select", abc-1);
				roiManager("Save", Output + name_a2 + ".tiff" + fs + "ROIs" + fs + "ROI_Cell.roi");
				open(path1);
				if (channels_a>1 || slices_a>1) {
					Stack.setSlice(sspi[abc-1]);
					Stack.setChannel(scpi[abc-1]);
					run("Duplicate...", " ");
					selectImage(name_a);
					close(); 
				}
				saveAs("Tiff", temp_directory + name_a2 + ".tiff");
			}
			close();

			//Saving of temporary files (multistack, multichannel, several cells per image are all subdivided into single-channel, -slice, and -cell-images and stored in temporary folders, sorted by channels)
			//These files will later be called by the analysis for intensity/profile analysis
			for (temp_save=1; temp_save<=slices_a; temp_save++) {
				if (multichannel==1) {
					open(path1); 
					for (channels=0; channels<channels_a; channels++) {
						Stack.setSlice(temp_save); 
						Stack.setChannel(channels+1);
						run("Duplicate...", " ");
						if (nRois>1) {
							if (slices_a>1) {
								if (temp_save<10) {
									saveAs("Tiff", chan_directories[channels] + name_a2 + "_Cell_" + abc + "_slice_0" + temp_save + ".tiff");
								} else {
								saveAs("Tiff", chan_directories[channels] + name_a2 + "_Cell_" + abc + "_slice_" + temp_save + ".tiff");
								}
							} else {
								saveAs("Tiff", chan_directories[channels] + name_a2 + "_Cell_" + abc + ".tiff");
							}
						} else {
							if (slices_a>1) {
								if (temp_save<10) {
									saveAs("Tiff", chan_directories[channels] + name_a2 + "_slice_0" + temp_save + ".tiff");
								} else {
									saveAs("Tiff", chan_directories[channels] + name_a2 + "_slice_" + temp_save + ".tiff");
								}
							} else {
								saveAs("Tiff", chan_directories[channels] + name_a2 + ".tiff");
							}
						}
						close();
					}
					close();
				} else {
					for (ot=0; ot<Channumber; ot++) {
						if (ot==0) {
							open(single_origins[ot]+list_channels_0[aaa]);
						} else if (ot==1) {
							open(single_origins[ot]+list_channels_1[aaa]);
						} else if (ot==2) {
							open(single_origins[ot]+list_channels_2[aaa]);
						} else if (ot==3) {
							open(single_origins[ot]+list_channels_3[aaa]);
						}
						if (nRois>1) {
							if (slices_a>1) {
								Stack.setSlice(temp_save); 
								run("Duplicate...", " ");
								if (temp_save<10) {
									saveAs("Tiff", chan_directories[ot] + name_a2 + "_Cell_" + abc + "_slice_0" + temp_save + ".tiff");
								} else {
									saveAs("Tiff", chan_directories[ot] + name_a2 + "_Cell_" + abc + "_slice_" + temp_save + ".tiff");
								}
								close();
							} else {
								saveAs(chan_directories[ot] + name_a2 + "_Cell_" + abc + ".tiff");
							}
						} else {
							if (slices_a>1) {
								Stack.setSlice(temp_save); 
								run("Duplicate...", " ");
								if (temp_save<10) {
									saveAs("Tiff", chan_directories[ot] + name_a2 + "_slice_0" + temp_save + ".tiff");
								} else {
									saveAs("Tiff", chan_directories[ot] + name_a2 + "_slice_" + temp_save + ".tiff");
								}
								close();
							} else {
								saveAs("Tiff", chan_directories[ot] + name_a2 + ".tiff");
							}
						}
						close();
					}
				}
			}
		}
	}
	setBatchMode(false);
}

//The file-list of the temp-directory now contains reference images with single channel and single slice images that each serve as podosome defining platform for the analysis of an entire hyperstack. 
//Dimensions (number of slices or channels per reference image) are saved into arrays which will be called upon in the analysis to define how many channels/slices per reference slice have to be analysed (simple: reassemble the divided hyperstack)
list1_temp=getFileList(temp_directory);
sum_slices=0;
for (su=0; su<slices_per_image.length; su++) {
	if (slices_per_image[su]==0) {
		slices_per_image[su]=1;
	}
	if (selected_channel_per_image[su]==0) {
		selected_channel_per_image[su]=1;
	}
	if (selected_slice_per_image[su]==0) {
		selected_slice_per_image[su]=1;
	}
	sum_slices+=slices_per_image[su];
}

//Initial Step 4 - Selection and saving of ROIs around podosome cluster

//If option was not deactivated in IS 2, every reference image is opened once and the ROI which restricts podosome identification can be defined by user, or skipped for individual images
if (cluster==1 && same_ROI==0) {
	for (aaa=0; aaa<list1_temp.length; aaa++) {
		roiManager("Reset");
		open(temp_directory+list1_temp[aaa]);
		name=getTitle();
		roiManager("Open", Output + name + fs + "ROIs" + fs + "ROI_Cell.roi");
		roiManager("Select", 0); 
		run("Flatten");
		name_x=getTitle(); 
		roiManager("Reset"); 
		selectImage(name);
		close();
		waitForUser("Select Podosome Cluster(s)", "Please select a ROI around the podosome cluster(s)\nand add it/them to the ROI manager (press 't').\nClick 'OK' to proceed after all clusters are selected.\nYou can proceed without selecting a cluster, as well."); 
		if (roiManager("Count")!=0) {
			roiManager("Save", Output + name + fs + "ROIs" + fs + "ROI_Cluster.zip");
		}
		selectImage(name_x);
		close();
	}
} else if (cluster==1 && same_ROI==1) {
	for (aaa=0; aaa<nRois; aaa++) {
		roiManager("Reset");
		open(temp_directory+list1_temp[aaa]);
		name=getTitle();
		roiManager("Open", Output + name + fs + "ROIs" + fs + "ROI_Cell.roi");
		roiManager("Select", 0); 
		run("Flatten");
		name_x=getTitle(); 
		roiManager("Reset"); 
		selectImage(name);
		close();
		waitForUser("Select Podosome Cluster(s)", "Please select a ROI around the podosome cluster(s)\nand add it/them to the ROI manager (press 't').\nClick 'OK' to proceed after all clusters are selected.\nYou can proceed without selecting a cluster, as well."); 
		if (roiManager("Count")!=0) {
			for (aab=0; aab<list1_temp.length/nRois; aab++) {
				roiManager("Save", Output + list1_temp[(aab*nRois) + aaa] + fs + "ROIs" + fs + "ROI_Cluster.zip");
			}
		}
		selectImage(name_x);
		close();
	}
}

//Initial Step 5 - Manual definition of analysis parameters

//Reference image is opened, selected cell ROI is opened (and saved as zip-file to make it easier to re-open it via drag and drop after analysis), permanently drawn onto the cell and UI is created
noise=newArray(list1_temp.length);
smoothsteps=newArray(list1_temp.length);
circlesize=newArray(list1_temp.length);
squaresize=newArray(list1_temp.length); 
noise[0]=20; //Replace with noise tolerance value that is shown by default
smoothsteps[0]=3; //Replace with number of smoothing steps that is shown by default
circlesize[0]=15; //Replace with default size of circular podosome selections;  
squaresize[0]=15; //Replace with default size of square podosome selections; Caution: do not set this to <2, as it will crash the program even when profiles are deactivated!
prev_image="Prev_Image";
for (aaa=0; aaa<list1_temp.length; aaa++) {
	if (aaa>0) {
		noise[aaa]=noise[aaa-1];
		smoothsteps[aaa]=smoothsteps[aaa-1];
		circlesize[aaa]=circlesize[aaa-1];
		squaresize[aaa]=squaresize[aaa-1];
	}
	if (same_detec==0 || aaa==0) {
		setBatchMode(true);
	}
	roiManager("Reset");
	open(temp_directory+list1_temp[aaa]);
	name=getTitle();
	if (bit==8) {
		run("8-bit");
	} else if (bit==16) {
		run("16-bit");
		run("Grays");
	}
	getPixelSize(unit_init, x_init, y_init);
	roiManager("Open", Output + name + fs + "ROIs" + fs + "ROI_Cell.roi");
	roiManager("Select", 0); 
	roiManager("Set Color", "yellow"); 
	roiManager("Save", Output + name + fs + "ROIs" + fs + "ROI_Cell.zip");
	File.delete(Output +  name + fs + "ROIs" + fs + "ROI_Cell.roi");
	selectWindow("Log");
	run("Close");
	if (same_detec==0 || aaa==0) {
		run("Flatten");
		name_x=getTitle(); 
		selectImage(name); 
		close();
		preview=1;
		u_prev=0;
		setBatchMode(false);

		//UI for setting up the parameters, the UI will be in a permanent loop as long as the preview is enabled; preview will run a short version of podosome detection, to mark up intensity/profile analysis areas around the podosomes
		//Several failsafes included, that prevent the Ui to end in case sizes are selected too small or less than 2 podosomes are detected (all those would lead to breaking of macro during analysis)
		while (preview==1 || circlesize[aaa]<1 || squaresize[aaa]<2 || u_prev<2) {
			Dialog.create("Choose the parameters");
			Dialog.addMessage("Please choose options for the podosome detection. \nCell: " + (aaa + 1) + "/" + list1_temp.length);
			Dialog.addNumber("prominence", noise[aaa]); 
			Dialog.addNumber("smoothing steps:", smoothsteps[aaa]); 
			Dialog.addMessage("Sizes of isolated podosome images (odd numbers).");
			Dialog.addNumber("circle size (intensity):", circlesize[aaa], 0, 6, "pixels (size >0!)"); 
			if (profile==1) {
				Dialog.addNumber("square size (profile):", squaresize[aaa], 0, 6, "pixels (size >1!)"); 
			}
			Dialog.addMessage("Scaling factor: " + x_init + " " + unit_init + "/pixel");
			Dialog.addMessage(circlesize[aaa] + " pixels (circle) = " + x_init*circlesize[aaa] + " " + unit_init);
			if (profile==1) {
				Dialog.addMessage(squaresize[aaa] + " pixels (square) = " + x_init*squaresize[aaa] + " " + unit_init);
			}
			Dialog.addMessage("detected podosomes = " + u_prev);
			Dialog.addCheckbox("Preview \n(uncheck box to save parameters and proceed)", true); //Replace with "false" to deactivate preview function by default
			Dialog.show();
			noise[aaa]=Dialog.getNumber();
			smoothsteps[aaa]=Dialog.getNumber();
			circlesize[aaa]=Dialog.getNumber();
			if (isNaN(circlesize[aaa])) {
				circlesize[aaa]=0;
			}
			if (profile==1) {
				squaresize[aaa]=Dialog.getNumber();
				if (isNaN(squaresize[aaa])) {
					squaresize[aaa]=0;
				}
			}

			//Preview-function, it is basically the truncated podosome detection function of the analysis, detection in ROI with FindMaxima-parameters and annotation of correct square and circle sizes
			preview=Dialog.getCheckbox();
			if (preview==1 || u_prev<2) {
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
				open(temp_directory+list1_temp[aaa]);
				prev_image=getTitle();
				if (bit==8) {
					run("8-bit");
				} else if (bit==16) {
					run("16-bit");
					run("Grays");
				} 
				for (smooth_prev=0; smooth_prev<smoothsteps[aaa]; smooth_prev++) {
					run("Smooth"); 
				}
				roiManager("Open", Output + name + fs + "ROIs" + fs + "ROI_Cell.zip");
				if (File.exists(Output + name + fs + "ROIs" + fs + "ROI_Cluster.zip")) {
					roiManager("Reset");
					roiManager("Open", Output + name + fs + "ROIs" + fs + "ROI_Cluster.zip");
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
				selectImage(prev_image);
				roiManager("Select", 0);
				run("Find Maxima...", "prominence=" + noise[aaa] + " output=List exclude");
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
				if (circlesize[aaa]>0 && squaresize[aaa]>0) {
					xx_prev=(circlesize[aaa]-1)/2;
					for(b_prev=0; b_prev<u_prev; b_prev++) {
						selectImage(prev_image);
						makeOval(x_prev[b_prev]-xx_prev, y_prev[b_prev]-xx_prev, circlesize[aaa], circlesize[aaa]);
						roiManager("Add");
						roiManager("Select", b_prev);
						roiManager("Set Color", "red"); 
					}
					if (profile==1) {
						xx_prev=(squaresize[aaa]-1)/2;
						for (b_prev=0; b_prev<u_prev; b_prev++) {
							selectImage(prev_image);
							makeRectangle(x_prev[b_prev]-xx_prev, y_prev[b_prev]-xx_prev, squaresize[aaa], squaresize[aaa]);
							roiManager("Add");
							roiManager("Select", b_prev+u_prev);
							roiManager("Set Color", "blue");
						}
					}
				}
			setBatchMode(false);
			roiManager("Show All without labels");
			}
			if (preview==0) {
				if (u_prev<2) {
					showMessage("Important", "More than 2 podosomes per cell are required for analysis.\nCurrent parameters for this image have not been saved.\nPlease repeat parameter settings for this image"); 
				}
				if (circlesize[aaa]<1 || squaresize[aaa]<2) {
					showMessage("Important", "Parameters for this image have not been saved! Please repeat!\nPlease pay special attention to the size restrictions for intensity and profile analysis!\nIntensity (circle): 1 pixels or more; profile (square): 2 pixels or more)");
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
	} else {
		selectImage(name); 
		close();
	}
}
roiManager("Show None");
run("Input/Output...", "jpeg=85 gif=-1 file=.txt use_file copy_column save_column"); //Options for results table layout
setBatchMode(true);
list_opener=0; //combined counter that goes up after each analysed image (so that analysis correctly openes x slices for hyperstack 1 and x+1...y as first to last slice for hyperstack 2)
cell_names=newArray(list1_temp.length); 
run("Plots...", "interpolate sub-pixel"); //Option for profile analysis
run("Text Window...", "name=Progress width=120 height=4 monospaced"); //Progress bar

//Frame for analysis - Detection of podosomes and saving of general metrics and parameters (step 1), analysis (step 2), saving of results per hyperstack (step 3), final saving of combined results (step 4)

//Step 1 - Detection of podosomes and saving of general metrics

//Opening one reference image after another to start analysis with podosome detection
for (bbb=0; bbb<list1_temp.length; bbb++) {
	if (!File.isDirectory(list1_temp[bbb])) {
		path1=temp_directory+list1_temp[bbb];
		open(path1);
		roiManager("Reset");
		name1=getTitle;
		Cell_name=substring(name1, 0, lengthOf(name1)-5);
		cell_names[bbb]=replace(Cell_name, " ", "_");
		bit=bitDepth();
		print("[Progress]", "\\Update:" + "Current image: Initiation\nCurrent channel: Initiation\nDone: " + (list_opener*Channumber) + "/" + sum_slices*Channumber + " (" + ((list_opener*Channumber)*100)/(sum_slices*Channumber) + "%)");
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
		roiManager("Open", Output + name1 + fs + "ROIs" + fs + "ROI_Cell.zip");
		run("Set Measurements...", "area redirect=None decimal=0");
		roiManager("Select", 0);
		roiManager("Measure");
		suma=getResult("Area", 0);
		selectWindow("Results");
		run("Close");

		//Replacing of cell area as area where podosomes shall be detected with the combined areas of podosome clusters, if they were defined in IS 4 by user
		if (File.exists(Output + name1 + fs + "ROIs" + fs + "ROI_Cluster.zip")) {
			roiManager("Reset");
			roiManager("Open", Output + name1 + fs + "ROIs" + fs + "ROI_Cluster.zip");
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
		
		//Detection of podosomes on duplicate of reference image, saving of individual podosomes in respective output folder
		selectImage(duplID);
		roiManager("Select", 0);
		run("Find Maxima...", "prominence=" + noise[bbb] + " output=List exclude");
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
		roiManager("Reset");
		xx=(circlesize[bbb]-1)/2;
		roiManager("Show None");
		for(b=0; b<u; b++) {
			selectImage(name1);
			makeOval(x[b]-xx, y[b]-xx, circlesize[bbb], circlesize[bbb]);
			roiManager("Add");
		}
		roiManager("Save", Output + name1 + fs + "ROIs" + fs + "ROIs_Podosomes.zip");

		//Combining of all podosome ROIs into one combined podosome area (CPA)-ROI
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

		//Measurement of generlas cell and CPA sizes and other parameters, creation of parameters table and saving in respective output folder
		Roi.getBounds(x_combine, y_combine, width_combine, height_combine);
		run("Set Measurements...", "area redirect=None decimal=0");
		selectImage(name1);
		roiManager("Select", 0);
		run("Measure");
		sumb=getResult("Area", 0);
		selectWindow("Results");
		run("Close");
		print("Image properties:");
		print("channels: " + Channumber);
		print("slices: " + slices_per_image[bbb]);
		print("lateral scalefactor (XY): " + x_size[bbb] + " " + unit[bbb] + "/pixel");
		if (slices_per_image[bbb]>1) {
			print("depth scalefactor (Z): " + z_size[bbb] + " " + unit[bbb] + "/pixel");
		}
		print("bit depth: " + bit + "-bit");
		print(" ");
		print("Analysis parameters:");
		if (norm_cell==1) {
			print("normalisation: Yes");
		} else {
			print("normalisation: No");
		}
		print("reference channel: " + chan_names[selected_channel_per_image[bbb]-1]);
		print("reference channel number: " + selected_channel_per_image[bbb]);
		print("reference slice: " + selected_slice_per_image[bbb]);
		print("prominence: " + noise[bbb]);
		print("smoothing steps: " + smoothsteps[bbb]);
		print("circle size: " + circlesize[bbb] + " pixel");
		if (profile==1) {
			print("square size: " + squaresize[bbb] + " pixel");
			print("rotation steps: " + rotation);
			print("degree per rotation: " + degree);
			print("profile comparison mode: " + res_auto_sort); 
		}
		print(" ");
		print("Detection summary:");
		print("cell area: " + suma + " " + unit[bbb] + "²");
		print("combined podosome area: " + sumb + " " + unit[bbb] + "²");
		print("podosome number: " + u);
		selectWindow("Log");
		saveAs("Text", Output + name1 + fs + "Parameters.txt");
		selectWindow("Log");
		run("Close");
		roiManager("Save", Output + name1 + fs + "ROIs" + fs + "ROIs_combined_podosome_area.zip");
		roiManager("Reset");

		//Creation of 2 general metrics results table, one with one one, which is saved into the respective cell folder and one that is adding one line for every reference image opened, which will be saved into combined resuls folder in the end of analysis
		run("Set Measurements...", "integrated redirect=None decimal=" + decimal);
		setResult("Parameter", 0, "Size cell area [" + unit[bbb] + "²]");
		setResult("Parameter", 1, "Size combined podosome area (CPA) [" + unit[bbb] + "²]");
		setResult("Parameter", 2, "Podosome number");
		setResult("Parameter", 3, "Podosome density (No. Podosomes/Cell) [1/" + unit[bbb] + "²]");
		setResult("Parameter", 4, "Podosome covered area (size CPA/Cell) [1/" + unit[bbb] + "²]");
		setResult(Cell_name, 0, suma);
		setResult(Cell_name, 1, sumb);
		setResult(Cell_name, 2, u);
		setResult(Cell_name, 3, u/suma);
		setResult(Cell_name, 4, sumb/suma);
		updateResults();
		if (slices_per_image[bbb]>1) {
			File.makeDirectory(Output + name1 + fs + "Stack results");
			selectWindow("Results");
			saveAs("Results", Output + name1 + fs + "Stack results" + fs + "General metrics" + data_ending);
			run("Close");
		} else {
			selectWindow("Results");
			saveAs("Results", Output + name1 + fs + "General metrics" + data_ending);
			run("Close");
		}
		if (bbb!=0) {
			IJ.renameResults("General metrics", "Results");
		}
		if (bbb==0) {
			setResult("Parameter", 0, "Size cell area [" + unit[bbb] + "²]");
			setResult("Parameter", 1, "Size combined podosome area (CPA) [" + unit[bbb] + "²]");
			setResult("Parameter", 2, "Podosome number");
			setResult("Parameter", 3, "Podosome density (No. Podosomes/Cell) [1/" + unit[bbb] + "²]");
			setResult("Parameter", 4, "Podosome covered area (size CPA/Cell) [1/" + unit[bbb] + "²]");
		}
		setResult(Cell_name, 0, suma);
		setResult(Cell_name, 1, sumb);
		setResult(Cell_name, 2, u);
		setResult(Cell_name, 3, u/suma);
		setResult(Cell_name, 4, sumb/suma);
		updateResults();
		IJ.renameResults("Results", "General metrics");
		run("Set Measurements...", "integrated redirect=None decimal=0");
		
		//Creation of single z plane subfolders (if more than one slice is present) for the preparation of profile analysis and saving of profile ROIs
		result_list=newArray(slices_per_image[bbb]);
		for (slice_save=1; slice_save<=slices_per_image[bbb]; slice_save++) {
			if(slices_per_image[bbb]>1) {
				save_path=Output + name1 + fs + "Slice " + slice_save + fs;
				File.makeDirectory(save_path);
				result_list[slice_save-1]="Slice " + slice_save + fs;
			} else {
				save_path=Output + name1 + fs;
			}
			if (data_save!="essential data") {
				File.makeDirectory(save_path + "Images");
			}
			if (profile==1) {
				File.makeDirectory(save_path + "Profiles");
				if (data_save!="essential data") {
					File.makeDirectory(save_path + "Profiles" + fs + "Images");
				}
				if (data_save=="+ extended data") {
					File.makeDirectory(save_path + "Profiles" + fs + "Single rotations");
				}
				xy=(squaresize[bbb]-1)/2;
				if (slice_save==1) {
					for(e=0; e<u; e++) {
						selectImage(name1);
						makeRectangle(x[e]-xy, y[e]-xy, squaresize[bbb], squaresize[bbb]);
						roiManager("Add");
					}
				}
				if (single_profiles==1) {
					File.makeDirectory(save_path + "Profiles" + fs + "Individual profiles");
					if (data_save=="+ extended data") {
						File.makeDirectory(save_path + "Profiles" + fs + "Individual profiles" + fs + "Single rotations");
					}
				}
				if (slice_save==1) {
					roiManager("Save", Output + name1 + fs + "ROIs" + fs + "ROIs_Podosomes_Profiles.zip");
					roiManager("Reset");
				}
			}
		}
		selectImage(name1);
		close();
		roiManager("Reset");
	}

	//Step 2 - Main analysis for each channel
	
	//Analysis of all channels and slices, for each slice first all channels are analysed, then the profile results for all channels of this slice are saven, then it proceeds
	for (slice_num=1; slice_num<=slices_per_image[bbb]; slice_num++) { //each slice of an hyperstack is analysed after another
		for (ana=0; ana<Channumber; ana++) { //each channel per hyperstack is analysed after anoher
			if (slices_per_image[bbb]>1) {
				save_path=Output + name1 + fs + "Slice " + slice_num + fs;
			} else {
				save_path=Output + name1 + fs;
			}
			count=ana; //counter for lines in combined results table
			Analysis(chan_directories[ana], chan_names[ana], slice_num); //function 1 (analysis) with function 2 (profile analysis) and 6 (single podosome profile analysis) inside it
		}
		if (profile==1) {
			save_profiles("original"); //function 3 (saving of profiles of all channels per individual slice)
			if (data_save=="+ extended data") {
				save_profiles("stack normed"); //function 3 (see above)
				save_profiles("z-projection and stack normed"); //function 3 (see above)
			}
		}
		list_opener+=1;
	}
	
	//Step 3 - Saving of stack results

	//Once the entire hyperstack of one reference image (which are looped in the frame of Step 1) is analysed in Step 2 (all channels, all slices), the stack results are saved in the respective cell folder
	if (slices_per_image[bbb]>1) {
		print("[Progress]", "\\Update:" + "Current image: Saving stack results\nCurrent channel: Saving stack results\nDone: " + (list_opener*Channumber) + "/" + sum_slices*Channumber + " (" + ((list_opener*Channumber)*100)/(sum_slices*Channumber) + "%)");
		sort_profiles_by_channel("(original)"); //function 4 (sorting profiles by channels for the entire stack and saving it together with 3D-models 
		if (data_save=="+ extended data") {
			sort_profiles_by_channel("(stack normed)");
			sort_profiles_by_channel("(z-projection and stack normed)");
		}
		if (!File.exists(Output + name1 + fs + "Stack results")) {
			File.makeDirectory(Output + name1 + fs + "Stack results");
		}
		IJ.renameResults("General cell intensities stack", "Results");
		selectWindow("Results"); 
		saveAs("Results", Output + name1 + fs + "Stack results" + fs + "General cell intensities stack" + data_ending);
		run("Close");
		IJ.renameResults("General cpa intensities stack", "Results");
		selectWindow("Results"); 
		saveAs("Results", Output + name1 + fs + "Stack results" + fs + "General cpa intensities stack" + data_ending);
		run("Close");
		for (sav=0; sav<Channumber; sav++) {
			IJ.renameResults("Podosome intensities_" + chan_names[sav] + "_stack", "Results");
			selectWindow("Results"); 
			saveAs("Results", Output + name1 + fs + "Stack results" + fs + "Podosome intensities (" + chan_names[sav] + ")" + data_ending);
			run("Close");
		}
	}
}
//After saving, the reference image is closed and the new reference image is openend, with new detection of podosomes and subsequent analysis of all channels and slices
//The results tables for combined results are carried over and new results will be added below the existing lines

// Step 4 - Sorting and saving of combined results after all analysis is conducted

//If at least 1 stack is present and a sorting method was selected, the profile stack results and general intensities saved within individual results folders will be combined and sorted by z plane
Output_list=getFileList(Output);
File.makeDirectory(Output + "Combined results");
Array.getStatistics(slices_per_image, min_sl, max_sl, mean_sl, stDev_sl);
if (res_auto_sort!="None" && max_sl>1) {
	profile_output=Output + "Combined results" + fs + "Stack comparison (profiles)" + fs;
	cell_intensities_output=Output + "Combined results" + fs + "Stack comparison (cell intensities)" + fs;
	cpa_intensities_output=Output + "Combined results" + fs + "Stack comparison (cpa intensities)" + fs;
	podosome_intensities_output=Output + "Combined results" + fs + "Stack comparison (podosome intensities)" + fs;

	//If automatic sorting is activated (needs profiles), the relative percentage table of stack profiles will be taken and the z slice with 100% in the reference channel will be taken as z=0; otherwise user selected plane stays z=0
	if (res_auto_sort=="Automatically detect z=0") {
		for (pp=0; pp<Output_list.length; pp++) {
			if (File.exists(Output + Output_list[pp] + fs + "Stack results" + fs + "Profiles (" + chan_names[selected_channel_per_image[pp]-1] + ") (original) (relative percentage)" + data_ending)) {
				run("Results... ", "open=[" + Output + Output_list[pp] + fs + "Stack results" + fs + "Profiles (" + chan_names[selected_channel_per_image[pp]-1] + ") (original) (relative percentage)" + data_ending + "]");
				n_sort=nResults;
				for (ppa=1; ppa<=slices_per_image[pp]; ppa++) {
					for (ppb=0; ppb<n_sort; ppb++) {
						max_sort=getResult("Slice " + ppa, ppb);
						if (max_sort==100) {
							selected_slice_per_image[pp]=ppa;
						}
					}
				}
				selectWindow("Results");
				run("Close"); 
			}
		}
	}
	
	//all lines below are function 5 in different normalisation states, and for different results tables some are only created if the saving of all data is activated
	if (profile==true) {
		File.makeDirectory(profile_output);
		for (po=0; po<chan_names.length; po++) {
			File.makeDirectory(profile_output + chan_names[po]);
		}
		results_comparison("(original)", "", "Profile"); //and below is function 5 - Combining profiles of all images and sortzing by z planes
		results_comparison("(original)", " (relative percentage)", "Profile");
		if (data_save=="+ extended data") {
			results_comparison("(stack normed)", "", "Profile"); 
			results_comparison("(stack normed)", " (relative percentage)", "Profile");
			results_comparison("(z-projection and stack normed)", "", "Profile");
			results_comparison("(z-projection and stack normed)", " (relative percentage)", "Profile");
		}
	}
	File.makeDirectory(cell_intensities_output);
	results_comparison("", "", "Cell intensities");
	File.makeDirectory(cpa_intensities_output);
	results_comparison("", "", "cpa intensities");
	File.makeDirectory(podosome_intensities_output);
	for (po=0; po<chan_names.length; po++) {
		File.makeDirectory(podosome_intensities_output + chan_names[po]);
	}
	results_comparison("", "", "Podosome intensities");
}

//Delete temporary files, rename results folders and save last intensity tables
print("[Progress]", "\\Update:" + "Current image: Finishing analysis \nCurrent channel: Finishing analysis \nDone: " + sum_slices*Channumber + "/" + sum_slices*Channumber + " (100%)");

//Deleting of temporary files of analysis data channel by channel
for (xxx=0; xxx<Channumber; xxx++) {
	list_temp=getFileList(chan_directories[xxx]);
	for (xxy=0; xxy<list_temp.length; xxy++) {
		File.delete(chan_directories[xxx]+list_temp[xxy]);
	}
}

//Saving of combined general results and podosome intensities in combined results folder, afterwards deleting of (now empty) temporary folders

IJ.renameResults("General cell intensities", "Results");
selectWindow("Results"); 
saveAs("Results", Output + "Combined results" + fs + "General cell intensities" + data_ending);
run("Close");
IJ.renameResults("General cpa intensities", "Results");
selectWindow("Results"); 
saveAs("Results", Output + "Combined results" + fs + "General cpa intensities" + data_ending);
run("Close");


for (sav=0; sav<Channumber; sav++) {
	IJ.renameResults("Podosome intensities_" + chan_names[sav], "Results");
	selectWindow("Results"); 
	saveAs("Results", Output + "Combined results" + fs + "Podosome intensities (" + chan_names[sav] + ")" + data_ending);
	run("Close");
	File.delete(chan_directories[sav]);
}

//Saving of general metrics in combined results folder
run("Set Measurements...", "integrated redirect=None decimal=" + decimal);
IJ.renameResults("General metrics", "Results");
selectWindow("Results"); 
saveAs("Results", Output + "Combined results" + fs + "General metrics" + data_ending);
run("Close");
run("Set Measurements...", "integrated redirect=None decimal=0");

//Deleting of the temporary reference images and reference folder
list_temp=getFileList(temp_directory);
for (xyy=0; xyy<list_temp.length; xyy++) {
	File.delete(temp_directory+list_temp[xyy]);
}
File.delete(temp_directory);

//Renaming of output folders (removing ".tiff"-datan ending from folder name
for (fr=0; fr<Output_list.length; fr++) {
	File.rename(Output + Output_list[fr], Output + substring(Output_list[fr], 0, Output_list[fr].length-5));
}
selectWindow("Log");
run("Close");
setBatchMode(false);
selectWindow("ROI Manager");
run("Close");
print("[Progress]", "\\Close");


//Embedded Functions

//Definition of function 1 - Analysis of every channel; no podosome identification, the positions from the reference channel are used.

//Analysis of all images, as with loops in "Step 2", first all channels of one slice are analysed one after another, then the remaining slices are processed, before stack is closed and new stack is analysed
//Opening of single-plane, single-channel images for analysis, measurement of cell intensity
function Analysis(source, protein, slice_number) { //variables in this order: path for the temporary input folder, channel name, number of slice within the hyperstack
	list2_temp=getFileList(source);
	if (!File.isDirectory(source+list2_temp[list_opener])) {
		path2=source+list2_temp[list_opener];
		open(path2);
		name2=getTitle;
		print("[Progress]", "\\Update:" + "Current image: " + name2 + "\nCurrent channel: " + protein + "\nDone: " + ((list_opener*Channumber) + count) + "/" + sum_slices*Channumber + " (" + (((list_opener*Channumber)+count)*100)/(sum_slices*Channumber) + "%)");
		selectImage(name2);
		if (bit==8) {
			run("8-bit");
		} else if (bit==16) {
			run("16-bit");
		}
		roiManager("Open", Output + name1 + fs + "ROIs" + fs + "ROI_Cell.zip");
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

		//Opening of podosome ROIs, duplication of podosomes into a podosome stack and analysis of intensity per podosome
		roiManager("Open", Output + name1 + fs + "ROIs" + fs + "ROIs_Podosomes.zip");
		if (bit==8) {
			newImage(protein, "8-bit black", circlesize[bbb], circlesize[bbb], u);
		} else if (bit==16) {
			newImage(protein, "16-bit black", circlesize[bbb], circlesize[bbb], u);
		}
		resArray=newArray(u); //Moved from commented out part
		for (g=0; g<u; g++) {
			selectImage(name2);
			roiManager("Select", g);
			run("Copy");
			selectImage(protein);
			setSlice(g+1);
			run("Paste");
			run("Select None");
			run("Measure");
			resArray[g]=getResult("RawIntDen", g);
		}
		selectWindow("Results");
		run("Close");
		selectImage(protein);
		if (data_save!="essential data") { 
			if (norm_cell==0) {
				saveAs("Tiff", save_path + "Images" + fs + "Podosomestack " + protein + ".tiff");
			} else {
				saveAs("Tiff", save_path + "Images" + fs + "Podosomestack " + protein + " normalised.tiff");
			}
		}
		close();
		roiManager("Reset");
		
		//Analysis of size and intensity of combined podosome area and saving of stack image, if selected in options
		roiManager("Open", Output + name1 + fs + "ROIs" + fs + "ROIs_combined_podosome_area.zip");
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
		if (data_save=="+ extended data") {
			if (norm_cell==0) {
				saveAs("Tiff", save_path + "Images" + fs + "Combined podosome area " + protein + ".tiff");
			} else {
				saveAs("Tiff", save_path + "Images" + fs + "Combined podosome area " + protein + " normalised.tiff");
			}
		}
		close();
		selectWindow("Results");
		run("Close");
		roiManager("Reset");
		
		//Profile analysis
		//Setting up the stack  based on the square podosome ROIs, detected in initiation
		if (profile==1) { 
			roiManager("Open", Output + name1 + fs + "ROIs" + fs + "ROIs_Podosomes_Profiles.zip");
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
				do_single_profiles(protein, "original"); //function 6, calculating individual profiles
			}
			do_profile(protein, "original", 0); //function 2, calculating average intensity profiles
			close(); 
			selectImage("Profname");
			
			//If all data are chosen to be saved, profile analysis (eventually with individual profiles) will also be done after normalisation of the podosome stack and additionally after normalisation of the average image
			if (data_save=="+ extended data") {
				run("Duplicate...", "duplicate");
				if (data_save!="essential data") {
					if (norm_cell==0) {
						saveAs("Tiff",  save_path + "Images" + fs + "Profilestack " + protein + ".tiff");
					} else {
						saveAs("Tiff",  save_path + "Images" + fs + "Profilestack " + protein + " normalised.tiff");
					}
				}
				close();
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
				if (data_save!="essential data") {
					if (norm_cell==0) {
						saveAs("Tiff",  save_path + "Images" + fs + "Profilestack " + protein + " (normed).tiff");
					} else {
						saveAs("Tiff",  save_path + "Images" + fs + "Profilestack " + protein + " (normed) and normalised.tiff");
					}
				}
			}
			close();
			roiManager("Reset");
		}
		
		//Saving and closing of all open images (cell inside ROI, original image)
		roiManager("Open", Output + name1 + fs + "ROIs" + fs + "ROI_Cell.zip");
		selectImage(name2);
		roiManager("Select", 0);
		Roi.getBounds(x_Cell, y_Cell, width_Cell, height_Cell);  
		run("Copy");
		if (bit==8) {
			newImage("Cell", "8-bit black", width_Cell, height_Cell, 1); 
		} else if (bit==16) {
			newImage("Cell", "16-bit black", width_Cell, height_Cell, 1); 
		}
		selectImage("Cell");
		run("Paste"); 
		run("Select None");
		if (data_save!="essential data") {
			if (norm_cell==0) {
				saveAs("Tiff", save_path + "Images" + fs + "Cell " + protein + ".tiff");
			} else {
				saveAs("Tiff", save_path + "Images" + fs + "Cell " + protein + " normalised.tiff");
			}
		}
		close();
		selectImage(name2);
		run("Select None");
		if (data_save!="essential data") {
			if (norm_cell==0) {
				saveAs("Tiff", save_path + "Images" + fs + "Source image " + protein + ".tiff");
			} else {
				saveAs("Tiff", save_path + "Images" + fs + "Source image " + protein + " normalised.tiff");
			}
		}
		close(); 
		roiManager("Reset");
		 
		//Saving of intensity results of each general intensities and of individual podosome intensities
		//When more than 1 slice is present per channel, first an individual table for both levels, where a line will be added for each slice that is analysed. Stack is saved before original image is switched (in analysis frame). 		
		if (slices_per_image[bbb]>1) {
			Cell_identifier=Cell_name + "_slice_" + slice_number;
			if (isOpen("General cell intensities stack")) {
				IJ.renameResults("General cell intensities stack", "Results"); //Check for rename in cleanup!
			}
			setResult("Channel", ana, protein);
			setResult("Slice " + slice_number, ana, sum3);
			updateResults();
			IJ.renameResults("Results", "General cell intensities stack"); //Check for rename in cleanup!
			if (isOpen("General cpa intensities stack")) {
				IJ.renameResults("General cpa intensities stack", "Results"); //Check for rename in cleanup!
			}
			setResult("Channel", ana, protein);
			setResult("Slice " + slice_number, ana, sum4);
			updateResults();
			IJ.renameResults("Results", "General cpa intensities stack"); //Check for rename in cleanup!			
			if (isOpen("Podosome intensities_" + protein + "_stack")) {
				IJ.renameResults("Podosome intensities_" + protein + "_stack", "Results"); 
			}
			for (res=0; res<u; res++) {
				setResult("Slice " + slice_number, res, resArray[res]);
			}
			updateResults();
			IJ.renameResults("Results", "Podosome intensities_" + protein + "_stack");
		} else {
			Cell_identifier=Cell_name;
		}
		//Second table for each level. The results of the entire analysis are saved here and single images/stacks are saved one after another inside the same table
		if (isOpen("General cell intensities")) {
				IJ.renameResults("General cell intensities", "Results"); //Check for rename in cleanup!
		}
		setResult("Channel", ana, protein);
		setResult(Cell_identifier, ana, sum3);
		updateResults();
		IJ.renameResults("Results", "General cell intensities"); //Check for rename in cleanup!

		if (isOpen("General cpa intensities")) {
				IJ.renameResults("General cpa intensities", "Results"); //Check for rename in cleanup!
		}
		setResult("Channel", ana, protein);
		setResult(Cell_identifier, ana, sum4);
		updateResults();
		IJ.renameResults("Results", "General cpa intensities"); //Check for rename in cleanup!
		if (isOpen("Podosome intensities_" + protein)) {
			IJ.renameResults("Podosome intensities_" + protein, "Results");
		}
		for (res=0; res<u; res++) {
			setResult(Cell_identifier, res, resArray[res]);
		}
		updateResults();
		IJ.renameResults("Results", "Podosome intensities_" + protein);
	}
}

//Definition of function 2 - Profile analysis

//The profile of the average podosome (obtained by z projection of the podosome stack) is calculated in this function
function do_profile(iname, def, dont_select) {
	run("Set Measurements...", "integrated redirect=None decimal=" + decimal);
	if (dont_select!=1) {
		selectImage("Profname");
		run("Z Project...", "projection=[Average Intensity]");
	}
	podavg=getTitle();
	y_avg=(getWidth-1)/2;
	width_avg=getWidth;

	//A results table is created in which the intensity measurements of the rotating profile line are saved; number of results = length of line, coloums of results = number of rotations
	for(k=0; k<rotation; k++) {
		selectImage(podavg);
		makeLine(0, y_avg, width_avg-1, y_avg);
		run("Rotate...", "angle=" + k*degree);
		profile=getProfile();
		for (kk=0; kk<profile.length; kk++) {
			setResult("Rotation " + k, kk, profile[kk]);
		}
	}
	updateResults();
	results=newArray(rotation); 
	prof_values=newArray(width_avg);
	stDevs=newArray(width_avg);

	//Average results from all rotations are taken (first all results from x=0 of the profile line for all rotations, then average of x=1 of all rotations until x=length of line)
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
	if (data_save=="+ extended data") {
		saveAs("Results", save_path + "Profiles" + fs + "Single rotations" + fs + "Single rotations " + iname + " (" + def + ")" + data_ending);
	}
	run("Close");
	run("Set Measurements...", "integrated redirect=None decimal=0");

	//Results tables are created and left open for all channels and all potential normalisation steps. They will be saved or closed in another function
	if (iname!=chan_names[0]) {
		IJ.renameResults("Prof_" + def, "Results"); 
	}
	for (m=0; m<width_avg; m++) {
		setResult(iname, m, prof_values[m]);
	}
	updateResults();
	IJ.renameResults("Results", "Prof_" + def);
	if (iname!=chan_names[0]) {
		IJ.renameResults("Prof_stDev_" + def, "Results"); 
	}
	for (m=0; m<width_avg; m++) {
		setResult(iname, m, prof_values[m]);
		setResult(iname + "_stDev", m, stDevs[m]);
	}
	updateResults();
	IJ.renameResults("Results", "Prof_stDev_" + def); 
	selectImage(podavg);
	if (data_save!="essential data") {
		saveAs("Tiff", save_path + "Profiles" + fs + "Images" + fs + "Z-projection " + iname + " (" + def + ").tiff");
	}
}

//Definition of function 3 - saving of profile results

//The average podosome profile results from function 2 are (depending on the status of saving options) saved or closed without saving. This is done for every channel and for every normalisation status
function save_profiles(norm_type) { 
	run("Set Measurements...", "integrated redirect=None decimal=" + decimal);
	IJ.renameResults("Prof_" + norm_type, "Results");
	selectWindow("Results"); 
	saveAs("Results", save_path + "Profiles" + fs + "Profiles (" + norm_type + ")" + data_ending);
	run("Close");
	IJ.renameResults("Prof_stDev_" + norm_type, "Results");
	selectWindow("Results");
	if (data_save=="+ extended data") {
		saveAs("Results", save_path + "Profiles" + fs + "Single rotations" + fs + "Mean with stDev of single rotations (" + norm_type + ")" + data_ending);
	}
	run("Close");
	if (single_profiles==1 && norm_type!="z-projection and stack normed") {
		IJ.renameResults("Single profs_" + norm_type, "Results");
		selectWindow("Results"); 
		saveAs("Results", save_path + "Profiles" + fs + "Individual profiles" + fs + "Mean with stDev of individual profiles (" + norm_type + ")" + data_ending);
		run("Close");
	}
	run("Set Measurements...", "integrated redirect=None decimal=0");
}

// Definition of function 4 - sorting profiles by channels

//When more than 1 slice is present in the analysis, then the single-slice profile results are sorted by channel, so that one table comprises all slices for one channel and one table per channel is created
//Firs the profile tables of the single slice folders are opened and he results are extracted into results tables, with one table per channel
function sort_profiles_by_channel(norm_type) {
	if (profile==1) {
		run("Set Measurements...", "integrated redirect=None decimal=" + decimal);
		for (res=0; res<result_list.length; res++) {
			run("Results... ", "open=[" + Output + name1 + fs + result_list[res] + "Profiles" + fs + "Profiles " + norm_type + data_ending + "]");
			nres=nResults;
			extract=newArray(nres);
			headings=split(String.getResultsHeadings);
			for (head=0; head<headings.length; head++) {
				for (headx=0; headx<nres; headx++) {
					extract[headx]=getResult(headings[head], headx);
				}
				IJ.renameResults("Results", "Temp");
				if (res!=0) {
					IJ.renameResults(headings[head] + "_sorted", "Results");
				}
				for (set=0; set<nres; set++) {
					setResult(substring(result_list[res], 0 , (lengthOf(result_list[res])-1)), set, extract[set]);
				}
				updateResults();
				IJ.renameResults("Results", headings[head] + "_sorted");
				IJ.renameResults("Temp", "Results"); 
			}
			selectWindow("Results");
			run("Close"); 
		}
		if (!File.exists(Output + name1 +  fs + "Stack results")) {
			File.makeDirectory(Output + name1 + fs + "Stack results");
		}

		//An image is created and based on the profile intensities of each individual slice a 3D-profile of the podosome with all channels is created (depending on input as 8- oder 16-bit)
		//Results for 3D-view are calculated by raw profile values
		if (bit==8) {
			newImage("Profiles-3D-view", "8-bit color-mode", nres, result_list.length, headings.length, 1, 1);
		} else if (bit==16) {
			newImage("Profiles-3D-view", "16-bit color-mode", nres, result_list.length, headings.length, 1, 1);
		}
		for (save_res=0; save_res<headings.length; save_res++) {
			IJ.renameResults(headings[save_res] + "_sorted", "Results");
			nres=nResults; 
			res_per=newArray(result_list.length*nres);
			heatmap=newArray(result_list.length*nres);
			colours=newArray("Cyan", "Magenta", "Yellow", "Grays");
			for (row=0; row<nres; row++) {
				for (col=0; col<result_list.length; col++) {
			   		res_per[(row*result_list.length)+col]=getResult(substring(result_list[col], 0 , (lengthOf(result_list[col])-1)), row);
				}
			}

			//Results for 3D-view are translated from raw values to normalised percentage (for results table) and to normalised values for 8- and 16-bit images 
			Array.getStatistics(res_per, min_rp, max_rp, mean_rp, stdDev_rp);
			new_res_per=newArray(res_per.length);
			for (rp=0; rp<res_per.length; rp++) {
				new_res_per[rp]=(res_per[rp]-min_rp)/(max_rp-min_rp)*100;
				if (bit==8) {
					heatmap[rp]=(res_per[rp]-min_rp)/(max_rp-min_rp)*255;
				} else if (bit==16) {
					heatmap[rp]=(res_per[rp]-min_rp)/(max_rp-min_rp)*65535;
				}
			}

			//Raw and relative percentage-normalised sorted results tables are saved
			selectWindow("Results"); 
			saveAs("Results", Output + name1 + fs + "Stack results" + fs + "Profiles (" + headings[save_res] + ") " + norm_type + data_ending);
			run("Close");
			for (row=0; row<nres; row++) {
				for (col=0; col<result_list.length; col++) {
			   		setResult(substring(result_list[col], 0, (lengthOf(result_list[col])-1)), row, new_res_per[(row*result_list.length)+col]);
				}
			}
			updateResults();
			selectWindow("Results"); 
			saveAs("Results", Output + name1 + fs + "Stack results" + fs + "Profiles (" + headings[save_res] + ") " + norm_type + " (relative percentage)" + data_ending);
			run("Close");

			//The 3D-image is created by setting the pixel on the individual sliced equivalent to the translated values above
			selectImage("Profiles-3D-view");
			if (headings.length>1) {
				Stack.setChannel(save_res+1);	
			}
			run(colours[save_res]);
			setMetadata("Label", headings[save_res]);
			for (xd=0; xd<nres; xd++) {
				for (yd=0; yd<result_list.length; yd++) {
					setPixel((nres-1)-xd, (result_list.length-1)-yd, heatmap[(((nres-1)-xd)*result_list.length)+yd]);
				}
			}
		}
		
		//Merging of all channels into a merged image, that is placed behind the stack, if more than 1 channels are present
		//If more than 1 channel is present, an additional montage image is created, that merges all channels into a single image; otherwise just the stack is saved
		if (headings.length>1) {
			selectImage("Profiles-3D-view");
			run("Duplicate...", "title=Merging duplicate");
			selectImage("Merging");
			run("Split Channels"); 
			if (headings.length==2) {
				run("Merge Channels...", "c5=C1-Merging c6=C2-Merging");
			} else if (headings.length==3) {
				run("Merge Channels...", "c5=C1-Merging c6=C2-Merging c7=C3-Merging");
			} else if (headings.length==4) {
				run("Merge Channels...", "c4=C4-Merging c5=C1-Merging c6=C2-Merging c7=C3-Merging");
			}
			selectImage("Profiles-3D-view");
			run("RGB Color");
			selectImage("Profiles-3D-view");
			close();
			run("Concatenate...", "  title=Profiles-3D-view image1=[Profiles-3D-view (RGB)] image2=RGB image3=[-- None --]");
			selectImage("Profiles-3D-view");
			run("Properties...", "channels=" + headings.length+1 + " slices=1 frames=1 pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000");
			for (label=0; label<headings.length; label++) {
				Stack.setChannel(label+1);
				setMetadata("Label", headings[label]);
			}
			Stack.setChannel(headings.length+1);
			setMetadata("Label", "Merge");
			selectImage("Profiles-3D-view");
			run("Make Montage...", "columns=" + headings.length+1 + " rows=1 scale=1");
			saveAs("Tiff",  Output + name1 + fs + "Stack results" + fs + "Profiles " + norm_type + " 3D view (Montage).tiff");
			close();
		}
		selectImage("Profiles-3D-view");
		saveAs("Tiff",  Output + name1 + fs + "Stack results" + fs + "Profiles " + norm_type + " 3D view (Stack).tiff");
		close();
	}
	run("Set Measurements...", "integrated redirect=None decimal=0");
}

//Definition of function 5 - Combining profiles of all images

//The profile stack results are taken (single slice results are ignored) and extracted, they are saved in results tables that are named by slice-selected slice. Based on the selected slice (user-defined or automatically determined)
//the profiles are sorted so that z=0, z=+-1... z=+-max_slice for all images are always taken into the same results table 
function results_comparison(norm_type, table_type, level) {
	print("[Progress]", "\\Update:" + "Current image: Sorting of stack results \nCurrent channel: Sorting of stack results \nDone: " + sum_slices*Channumber + "/" + sum_slices*Channumber + " (100%) \nSorting: " + level + table_type);
	run("Set Measurements...", "integrated redirect=None decimal=" + decimal);
	colours_2=newArray("Cyan", "Magenta", "Yellow", "Grays");
	for (save_prof=0; save_prof<chan_names.length; save_prof++) { //channels after another
		for (xb=0; xb<Output_list.length; xb++) { //images after another
			if (level=="Profile") {
				input=Output + Output_list[xb] + fs + "Stack results" + fs + "Profiles (" + chan_names[save_prof] + ") " + norm_type + table_type + data_ending;
				comp_save=profile_output + chan_names[save_prof] + fs;
			} else if (level=="Cell intensities") {
				input=Output + Output_list[xb] + fs + "Stack results" + fs + "General cell intensities stack" + data_ending;
				comp_save=cell_intensities_output;
			} else if (level=="cpa intensities") {
				input=Output + Output_list[xb] + fs + "Stack results" + fs + "General cpa intensities stack" + data_ending;
				comp_save=cpa_intensities_output;
			} else if (level=="Podosome intensities") {
				input=Output + Output_list[xb] + fs + "Stack results" + fs + "Podosome intensities (" + chan_names[save_prof] + ")" + data_ending;
				comp_save=podosome_intensities_output + chan_names[save_prof] + fs;
			}
			if (File.exists(input)) {
				run("Results... ", "open=[" + input + "]");
				nres_prof=nResults;
				copied_prof=newArray(nres_prof*slices_per_image[xb]); //results-array with the number of results*number of slices 
				for (yb=1; yb<=slices_per_image[xb]; yb++) {//for every slice after another
					for (nb=0; nb<nres_prof; nb++) {//for all data points of the results (e.g. single data points of profile line)
						copied_prof[((yb-1)*nres_prof)+nb]=getResult("Slice " + yb, nb); //extracting results from results table
					}
				}
				selectWindow("Results"); 
				run("Close");
				for (yx=1; yx<=slices_per_image[xb]; yx++) {//for every slice after another
					if (isOpen("res_temp_z_" + yx-selected_slice_per_image[xb])) {
						IJ.renameResults("res_temp_z_" + yx-selected_slice_per_image[xb], "Results"); 
					}
						for (nx=0; nx<nres_prof; nx++) {//number of results per table
							if (level=="Cell intensities" || level=="cpa intensities") {
								for (xp=0; xp<chan_names.length; xp++) {
										setResult("Channel", xp, chan_names[xp]);
								}
							}
							setResult(cell_names[xb] + "_z_" + (yx), nx, copied_prof[((yx-1)*nres_prof)+nx]);
						}
					updateResults();
					IJ.renameResults("Results", "res_temp_z_" + yx-selected_slice_per_image[xb]);
				}
			}
		}
		// Only in the mode for profile comparison with 
		if (norm_type=="(original)" && table_type==" (relative percentage)" && level=="Profile") {
			n_output=getFileList(comp_save); //number of results for profile comparison (raw values) are determining the height of the 3D-stack (number of slices is equal to number of tables in output folder)
			heat_count=0;
			if (!isOpen("Profiles-3D-view")) {
				if (bit==8) {
					newImage("Profiles-3D-view", "8-bit color-mode", nres_prof, n_output.length, chan_names.length, 1, 1);
				} else if (bit==16) {
					newImage("Profiles-3D-view", "16-bit color-mode", nres_prof, n_output.length, chan_names.length, 1, 1);
				}
			}
			selectImage("Profiles-3D-view");
			if (chan_names.length>1) {
				Stack.setChannel(save_prof+1);	
			}
			run(colours_2[save_prof]);
		}
		//Selecting all created tables after another and saving them as compared results to the combine results folder, profile stack and nmontage for average results is created
		for (zb=1; zb<=(max_sl*2)-1; zb++) { //select tables with the maximum range of table names (nSlice=9--> from z=-8 to z=8); not present tables will be ignored
			if (isOpen("res_temp_z_" + (max_sl-zb))) { //highest z-plane will be done first and tables are succesively decreasing into -z
				IJ.renameResults("res_temp_z_" + (max_sl-zb), "Results");
				if (norm_type=="(original)" && table_type==" (relative percentage)" && level=="Profile") {
					headings_2=split(String.getResultsHeadings);
					for (fa=0; fa<nres_prof; fa++) { //for all number of results (length of profile line) after another
						temp_res=newArray(headings_2.length);
						for (fb=0; fb<headings_2.length; fb++) { //for all the different cells that have been compared after another
							temp_res[fb]=getResult(headings_2[fb], fa);
						}
						Array.getStatistics(temp_res, temp_min, temp_max, temp_mean, temp_stdDev);
						selectImage("Profiles-3D-view");
						if (bit==8) {
							setPixel(fa, heat_count, temp_mean*(255/100)); //setting the pixels from (Y-direction) top to down (highest to lowest z plane) and from (X-direction) left to right (length of profile line)
						} else if (bit==16) {
							setPixel(fa, heat_count, temp_mean*(65535/100));
						}
					}
					heat_count+=1; //progresses whenever one slice has been averaged
				}
				selectWindow("Results");
				if (level=="Cell intensities" || level=="cpa intensities") {
					if (max_sl-zb<1) {
						saveAs("Results", comp_save + level + " z_" + max_sl-zb + data_ending);
					} else {
						saveAs("Results", comp_save + level + " z_+" + max_sl-zb + data_ending);
					}
				} else if (level=="Podosome intensities") {
					if (max_sl-zb<1) {
						saveAs("Results", comp_save + level + " " + chan_names[save_prof] + " z_" + max_sl-zb + data_ending);
					} else {
						saveAs("Results", comp_save + level + " " + chan_names[save_prof] + " z_+" + max_sl-zb + data_ending);
					}
				} else {
					if (max_sl-zb<1) {
						saveAs("Results", comp_save + level + " " + norm_type + table_type + " " + chan_names[save_prof] + " z_" + max_sl-zb + data_ending);
					} else {
						saveAs("Results", comp_save + level + " " + norm_type + table_type + " " + chan_names[save_prof] + " z_+" + max_sl-zb + data_ending);
					}
				}
				run("Close");
			}
		}

		//Condition to not analyse results once for every channel if they are cell/cpa intensity tables (already have all channels combined, only has to be done once
		if (level=="Cell intensities" || level=="cpa intensities") {
			save_prof=chan_names.length-1;
		}
	}

	//If the relative percentage podosome profiles are processed, the 3D-overview will be saved as stack and as montage (comparable to individual stack results per cell/ function 4), montage is only done with more than 1 channels
	if (norm_type=="(original)" && table_type==" (relative percentage)" && level=="Profile") {
		if (chan_names.length>1) {
			selectImage("Profiles-3D-view");
			run("Duplicate...", "title=Merging duplicate");
			selectImage("Merging");
			run("Split Channels"); 
			if (chan_names.length==2) {
				run("Merge Channels...", "c5=C1-Merging c6=C2-Merging");
			} else if (chan_names.length==3) {
				run("Merge Channels...", "c5=C1-Merging c6=C2-Merging c7=C3-Merging");
			} else if (chan_names.length==4) {
				run("Merge Channels...", "c4=C4-Merging c5=C1-Merging c6=C2-Merging c7=C3-Merging");
			}
			selectImage("Profiles-3D-view");
			run("RGB Color");
			selectImage("Profiles-3D-view");
			close();
			run("Concatenate...", "  title=Profiles-3D-view image1=[Profiles-3D-view (RGB)] image2=RGB image3=[-- None --]");
			selectImage("Profiles-3D-view");
			run("Properties...", "channels=" + chan_names.length+1 + " slices=1 frames=1 pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000");
			for (label_b=0; label_b<chan_names.length; label_b++) {
				Stack.setChannel(label_b+1);
				setMetadata("Label", chan_names[label_b]);
			}
			Stack.setChannel(chan_names.length+1);
			setMetadata("Label", "Merge");
			selectImage("Profiles-3D-view");
			run("Make Montage...", "columns=" + chan_names.length+1 + " rows=1 scale=1");
			saveAs("Tiff",  profile_output + fs + "Profiles " + norm_type + " 3D view (Montage).tiff");
			close();
		}
		selectImage("Profiles-3D-view");
		saveAs("Tiff", profile_output + fs + "Profiles " + norm_type + " 3D view (Stack).tiff");
		close();
	}
	run("Set Measurements...", "integrated redirect=None decimal=0");
}

//Definition of function 6 - Single podosome profile analysis of individual podosomes

//This function is close to the function 2, with the exception that it does not take the z projection of the podosome stacks, but the entire stack itself to do profiles on every single podosome
//Also the single rotations are saved into an additional results table. This function could possibly be discarded, thus documentation is scarce
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
		if (data_save=="+ extended data") {
			saveAs("Results", save_path + "Profiles" + fs + "Individual profiles" + fs + "Single rotations" + fs + "Podosome " + a_single + " " + channel_name + " (" + norm_status + ")" + data_ending);
		} 			
	}
	run("Close");
	if (data_save=="+ extended data") {
		for (sa=0; sa<n_single; sa++) {
			for (sb=0; sb<width_single; sb++) {
				setResult("Podosome " + sa + 1, sb, slices_single[(width_single*sa)+sb]);
				setResult("Slice " + sa + 1, sb, stDev_single[(width_single*sa)+sb]);
			}
		}
		updateResults();
		selectWindow("Results");
		saveAs("Results", save_path + "Profiles" + fs + "Individual profiles" + fs + "Single rotations" + fs + "Mean with stDev of single rotations " + channel_name + " (" + norm_status + ")" + data_ending);
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
	saveAs("Results", save_path + "Profiles" + fs + "Individual profiles" + fs + "Individual profiles " + channel_name + " (" + norm_status + ")" + data_ending);
	run("Close");
	if (channel_name!=chan_names[0]) {
		IJ.renameResults("Single profs_" + norm_status, "Results"); 
	}
	for (g_single=0; g_single<width_single; g_single++) {
		setResult("Mean " + channel_name, g_single, means[g_single]);
		setResult("stDev " + channel_name, g_single, stDevs[g_single]);
	}
	updateResults();
	selectWindow("Results");
	IJ.renameResults("Results", "Single profs_" + norm_status); 
	run("Set Measurements...", "integrated redirect=None decimal=0");
	selectImage("Profname");
	run("Select None");
	setSlice(1);
}