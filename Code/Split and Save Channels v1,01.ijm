waitForUser("Please open all your files first! If you use the\nBio-Formats Importer, please do NOT split planes and\nchannels there. Just open all images as hyperstack!\nClick 'OK' if all images are opened.");
Dialog.create("Assign Channels");
Dialog.addString("Channel 1:", "F-actin", 10);
Dialog.addString("Channel 2:", "Vinculin", 10);
Dialog.addString("Channel 3:", "Myosin IIA", 10);
Dialog.addString("Channel 4:", "Additional", 10);
Dialog.addSlider("Channel number:" 1, 4, 2);
Dialog.addNumber("Remove first letters:", 9, 0, 1, "e.g. 'Test.tif-Series-01' will be 'Series-01'");
Dialog.addNumber("Remove last letters:", 4, 0, 1, "e.g. 'Test.tif' will be 'Test'");
Dialog.show();
Chan_1=Dialog.getString();
Chan_2=Dialog.getString();
Chan_3=Dialog.getString(); 
Chan_4=Dialog.getString();
number=Dialog.getNumber();
begin=Dialog.getNumber();
end=Dialog.getNumber(); 
Output=getDirectory("Choose a path to save");
File.makeDirectory(Output + "/" + Chan_1);
if (number>1) {
	File.makeDirectory(Output + "/" + Chan_2);
	if (number>2) {
		File.makeDirectory(Output + "/" + Chan_3);
		if (number<3) {
			File.makeDirectory(Output + "/" + Chan_4);
		}
	}
}
setBatchMode(true); 
n=nImages;
for (a=0; a<n; a++) {
	title=getTitle();
	name=substring(title, begin, lengthOf(title)-end);
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit, pixelWidth, pixelHeight);
	if (channels>4) {
		exit("Only 4 channels per image supported by this and the Poji macro");
	}
	bit=bitDepth();
	complete=slices*channels;
	for (stack=0; stack<slices; stack++) {
		for (colour=1; colour<=channels; colour++) {
			selectImage(title);
			if (complete>1) {
				setSlice((stack*channels)+colour);
			}
			run("Copy");
			newImage("Temporary", bit + " black",  width, height, 1);
			run("Set Scale...", "distance=1 known=" + pixelWidth + " unit=" + unit);
			run("Paste");
			run("Select None"); 
			if (stack<10) {
				if (colour==1) {
					saveAs("Tiff", Output + "/" + Chan_1 + "/" + name + " Z=0" + stack + " C=" + colour + ".tiff");
				} else if (colour==2) {
					saveAs("Tiff", Output + "/" + Chan_2 + "/" + name + " Z=0" + stack + " C=" + colour + ".tiff");
				} else if (colour==3) {
					saveAs("Tiff", Output + "/" + Chan_3 + "/" + name + " Z=0" + stack + " C=" + colour + ".tiff");
				} else if (colour==4) {
					saveAs("Tiff", Output + "/" + Chan_4 + "/" + name + " Z=0" + stack + " C=" + colour + ".tiff");
				}
			} else {
				if (colour==1) {
					saveAs("Tiff", Output + "/" + Chan_1 + "/" + name + " Z=" + stack + " C=" + colour + ".tiff");
				} else if (colour==2) {
					saveAs("Tiff", Output + "/" + Chan_2 + "/" + name + " Z=" + stack + " C=" + colour + ".tiff");
				} else if (colour==3) {
					saveAs("Tiff", Output + "/" + Chan_3 + "/" + name + " Z=" + stack + " C=" + colour + ".tiff");
				} else if (colour==4) {
					saveAs("Tiff", Output + "/" + Chan_4 + "/" + name + " Z=" + stack + " C=" + colour + ".tiff");
				}
			}
			close();
		}
	}
	selectImage(title);
	close();
}
setBatchMode(false);