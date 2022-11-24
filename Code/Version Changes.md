# Poji

v1,00:

Version as presented in the associated publication.

v1,10:

Added: Option to additionally save profile results of all analysed images (sorted by channels) in a new folder called "Combined results".

Added: Preview window for setting of detection parameters now shows the number of detected podosomes.

Added: A warning is shown when the assigned results folder is not empty (danger of macro errors or overwriting of old results). User has to confirm to proceed. Declining will reset the macro (temporary folders are deleted) and the macro has to be restarted.

Changed: Results tables that included general information and single podosome intensities renamed from "Results (channel name)" to "Intensities (Channel name)". These results tables are now saved in the folder "Combined results".

Changed: Fixed file-separator replaced by automatic file-seperator to ensure compatibility with different OS.

v2,00:

Added: Now also supports the input of hyperstacks. Instead of splitting them into channels and stacks, hyperstacks can be processed by the macro and only the folder in which hyperstacks are present has to be selected. Analysis of several stacks at once is now possible.  Still, data should be comparable (same number of channels in the same order). 

Added: Stack profile results are saved together with intensity results inside one folder rather than profiles results being saved in individual slice result folders.

Added: 3D-model of podosomes when profile analysis is activated in images with more than 2 slices. 3D-model will be saved in the stack results folder as multichannel-image with a model for each channel together with merge.

Added: New folder with comparison between results of different stacks that were analysed together. Profile results can be sorted for better comparison between stacks that might differ in number of slices and that have detected podosomes on different reference slices. Comparison is done by defining one slice as z=0 and assigning all other planes to being slice z=-x and z=+x in realtion to z=0. Z=0 can be defined by the user (as slice for podosome detection) or automatically detected (plane with highest fluorescence intensity in reference channel is z=0).

Added: Several failsafes and warnings to prevent the assignment of wrong result folders and certain settings of detection parameters that would have crashed the macro.

Added: Several updates for the UI to facilitate navigation through the interfaces.  

Changed: Input of single channel and slice images is still supported. Instead of assigning a number of channels before and opening a correlating number of folders, the macro automatically detects if input images are not multichannel-images and lets the user decide if additional channels shall be assigned. After a maximum of 4 channels or after the user deactivates the option to add more channels, the macro proceedes.

Changed: ROI-selection of several cells in one image can be done in different channels and slices. Reference slice does not have to be channel 1, but can be freely chosen.

Changed: Parameters table and ROIs are now saved only once for stack analyses, instead of saving them for each single slice. Reworked contents of the parameters table.

Changed: High number of small changes, that ensure correct loading and saving of data in the correct order and to prevents crashes due to sample naming.


Removed: The compatibility with hyperstacks removes the need for one folder that is filled with the same slice for stack analysis. Reference channel and slice for stack analysis can now be assigned in in the hyperstack during the macro. Reference channel and slice can be freely chosen inbetween images and even in between different cells on the same image.

Updated: "Noise" in find-maxima function changed to "prominence" as it is in the official wording of FIJI. This might change the number of detected podosomes in comparison to the old version slightly, but is in line with the current state of the function.

v2,10: 
(in short, update coming soon)
Includes information about voxel instead of just pixel, rearranged analysis ables to make data handling easier, fixed UI errors due to FIJI-version changes, include quick 3D overview of podosomes in results folder

# Split and Save Channels (not needed anymore for Poji versions v2,00 and higher)


v1,00:

Version as presented in the associated publication.

v1,01:

Changed: Labels for z slices changed from "0-9" to "00-09" to ensure correct order of slices "00-09" in front of "10-99" during Poji-analysis.

v1,02:

Changed: Labels are now only renamed if more than 10 stack slices are present.

Changed: Fixed file-separator replaced by automatic file-seperator to ensure compatibility with different OS.
