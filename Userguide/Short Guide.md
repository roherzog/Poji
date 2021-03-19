# Until update of userguide for v2,00 gets uploaded, userguide for v1,10 is valid and this short guide can be used to navigate through all updated interfaces

1. Images have to be present inside a single folder (if hyperstacks) or split by channels in different folders. Folders shall only contain images and no subfolders. Hyperstacks shall have the same amount and order of channels (number of slices can differ). 
2. Start the macro.
3. Select input folder (if hyperstack) or folder of first channel (in seperated channels) with activating the option to add channels afterwards.
4. Assign results folder (this folder has to be empty to ensure that results are not overwriting other data).
5. Set up analysis options.
5-1. If profile analysis is activated, determine the radius for the profile analysis (note that the profile line goes through the center of the image from the left to the right side. Thus, a 180-degree rotation covers the whole structure, a 360-degree will create symmetric profiles, as every pixel is measured once right from center and once left from center).
7. Select the right channel and slice for podosome detection (if hyperstack) and draw a ROI around the cell outline. Several cells per image can be assigned, ROIs for this can be assigned on different slices and channels per cell.
8. Optional: Draw podosome clusters inside the isolated cells. Podosomes will only be detected in this area. Several ROIs per cell can be assigned. This step can be skipped without assigning a cluster; podosome detection will then be done in entire cell area.
9. Set up detection parameters. Pressing 'OK' will show a preview image with current parameters. To save the current parameters and to proceed, deactivate the preview function. Note the restrictions for this step (circle size >0; square size >1; podosome number >1).
10. Macro will automatically do the rest. Wait until the process bar disappeares, only then is the macro finished.  

To change default setings go to code lines:
11 (change default channel names);
110-123 (default analysis options)
138-139 (Default profile rotation options)
366-369 + 422 (Default parameter options) 
