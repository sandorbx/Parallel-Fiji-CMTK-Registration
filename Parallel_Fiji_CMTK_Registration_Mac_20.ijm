#@ String (label= "Choose an operation to perform", choices={"Affine and Warp Registration", "Affine Registration"}, style="listBox", description="Affine and warp means a full non rigid registration, in case of suboptimal output try to run just affine and make sure it gives a good alignment") operation
#@ String (label= "Registration Parameter Preset", choices={"None", "Full Flybrain(Cachero-Ostrovksy_2010)", "VNC"}, style="listBox", description="If active will use default affine and warp parameters instead of user settings under affine and warp parameters") preset

#@ String (visibility=MESSAGE, value=" Input&Output options                                       ", required=false) io

#@ File (label = "Output directory", style = "directory") reg_dir
#@ File (label = "reference brain (file)") refbrain
#@ File (label = "images to register (directory)", description="every image file must be named like 'yourimagename_01' 'yourimagename_02' and so on, batch mode is automatic – every scan in the folder tree will be registered", style = "directory") image_dir
#@ boolean (label = "Show results list (in the list double click to open an image)") show

#@ String (visibility=MESSAGE, value=" Compute options                                       ", required=false) compute_options

#@ boolean (label = "Skip final resolution step for speed", description="skips the final resolution step in multi level optimization, speeds up computation on high res images without notable loss in quality") res_skip
#@ Integer (label="Number of compute threads to use", style="slider", min=1, max=160, stepSize=1, value=160) T
#@ Integer (label="Number of parallel running jobs", style="slider", min=1, max=20, stepSize=1, value=1, description="In case of several scans in the directory you can schedule the processing in parallel groups, keep in mind your available memory") para

#@ String (visibility=MESSAGE, value=" Reformat options                                       ", required=false) ref
#@ boolean (label = "Output overlay avi") avi_out
#@ boolean (label = "reformat channel 01") rx1
#@ boolean (label = "reformat channel 02") rx2
#@ boolean (label = "reformat channel 03") rx3
#@ boolean (label = "reformat channel 04") rx4

#@ String (visibility=MESSAGE, value=" Affine Parameters                                       ", required=false) section2

#@ String (label= "Initial affine method", choices={"--centers-of-mass", "--principal-axes", "center-template"}, style="listBox") init_mode
#@ String (label= "Affine registration metric", choices={"Normalized Mutual Information", "Standard Mutual Information", "Correlation Ratio", "Mean Squared Difference", "Normalized Cross Correlation"}, style="listBox") affine_reg_metric_string
#@ Float (label="Exploration [Initial optimizer step size]", value=8) affine_X
#@ Float (label="Accuracy [Final optimizer step size]", value=0.8) affine_accuracy
#@ Integer (label="Degrees of freedom first pass", style="slider", min=1, max=9, stepSize=1, value=6) dof1
#@ Integer (label="Degrees of freedom second pass", style="slider", min=1, max=12, stepSize=1, value=9) dof2

#@ String (visibility=MESSAGE, value=" Warp Parameters                                       ", required=false) section3
#@ String (label= "Warp registration metric", choices={"Normalized Mutual Information", "Standard Mutual Information", "Correlation Ratio", "Mean Squared Difference", "Normalized Cross Correlation"}, style="listBox") warp_reg_metric_string
#@ Integer (label="initial exploration step size", value=26) X
#@ Float (label="Accuracy [Final exploration step size]", value=0.8) warp_accuracy 
#@ Integer (label="coarsest resampling", value=8) C
#@ Integer (label="Refine grid", value=4) R
#@ Integer (label="grid size(aim for three grid points along the shortest axis)", value=80) G
#@ String (label= "Compute mode", choices={"--fast", "--accurate"}, style="listBox", description="Accurate mode may give slightly better result with substantially longer compute time, use --fast if unsure") speed
#@ boolean (label = "Output Jacobian determinant map") jacobi_out

// Presets handling
if(preset=="Full Flybrain(Cachero-Ostrovksy_2010)") {
	init_mode ="--centers-of-mass";
	affine_reg_metric_string ="Normalized Mutual Information";
	affine_X =16;
	affine_accuracy =0.8;
	dof1 =6;
	dof2 =9;
	warp_reg_metric_string="Normalized Mutual Information";
	X =26;
	warp_accuracy =0.4;
	C =8;
	R =4;
	G =80;
	speed ="--fast";	
}

if(preset=="VNC") {
	init_mode ="--centers-of-mass";
	affine_reg_metric_string ="Normalized Mutual Information";
	affine_X =16;
	affine_accuracy =0.8;
	dof1 =6;
	dof2 =9;
	warp_reg_metric_string="Normalized Mutual Information";
	X =30;
	warp_accuracy =0.4;
	C =8;
	R =4;
	G =95;
	speed ="--fast";	
}

function calc_para_cycles(length, para) {
	a = length / para;
	r = length % para;
	if (r != 0) {
		a = substring(a, 0, lastIndexOf(a, "."));
		a = parseInt(a);
		a = a + 1;	
	}
	cycles = a;
	return cycles;
}

function build_directory_path_list(dir, dir_list) {
	list = getFileList(dir);
	for (i = 0; i < list.length; i++) {
		if (endsWith(list[i], "/")) {
			path = dir + list[i];
			dir_list = Array.concat(dir_list, path);
			dir_list = build_directory_path_list(path, dir_list);			
		}          
	}
	return dir_list;
}

function make_reformat_path_list(name, imagefile_list, images_path, rx1, rx2, rx3, rx4) {
	reformat_list = newArray();
	if (rx1 == 1) {
		for (i = 0; i < imagefile_list.length; i++) {
			if (matches(imagefile_list[i], name + "_01.*")) {
				path = images_path + imagefile_list[i];
				reformat_list = Array.concat(reformat_list, path);
			}
		}
	}
	if (rx2 == 1) {
		for (i = 0; i < imagefile_list.length; i++) {
			if (matches(imagefile_list[i], name + "_02.*")) {
				path = images_path + imagefile_list[i];
				reformat_list = Array.concat(reformat_list, path);
			}
		}
	}
	if (rx3 == 1) {
		for (i = 0; i < imagefile_list.length; i++) {
			if (matches(imagefile_list[i], name + "_03.*")) {
				path = images_path + imagefile_list[i];
				reformat_list = Array.concat(reformat_list, path);
			}
		}
	}
	if (rx4 == 1) {
		for (i = 0; i < imagefile_list.length; i++) {
			if (matches(imagefile_list[i], name + "_04.*")) {
				path = images_path + imagefile_list[i];
				reformat_list = Array.concat(reformat_list, path);
			}
		}
	}
	return reformat_list;															
}

function make_imagefile_list(image_dir) {
	list = getFileList(image_dir);
	list = Array.sort(list);
	image_list = newArray();
	for (i = 0; i < list.length; i++) {
		if (matches(list[i], ".*\\.(nrrd|PIC|nii)$"))
			image_list = Array.concat(image_list, list[i]);
	}
	return image_list;	
}

function reformatx(reg_folder_path, refbrain_path, reformat_list, transf_list) {
	reformatx_command = "";
	for (i = 0; i < reformat_list.length; i++) {
		outfilename = File.getName(reformat_list[i]);
		outfilename = substring(outfilename, 0, lastIndexOf(outfilename, "."));
		if (operation == "Affine Registration") {
			command = "cd " + reg_folder_path + "; cmtk reformatx --pad-out 0 -o Reformatted" + File.separator + "affine_" + outfilename + ".nrrd --floating " + reformat_list[i] + " " + refbrain_path + " " + transf_list + " & ";
		} else if (jacobi_out == 1 && endsWith(outfilename, "_01")) {			
			command = "cd " + reg_folder_path + "; cmtk reformatx --jacobian-correct-global --pad-out 0 -o Reformatted" + File.separator + "jacobian_warp_" + outfilename + ".nrrd --floating " + reformat_list[i] + " " + refbrain_path + " --jacobian " + transf_list + " & " +
			          "cmtk reformatx --pad-out 0 -o Reformatted" + File.separator + "warp_" + outfilename + ".nrrd --floating " + reformat_list[i] + " " + refbrain_path + " " + transf_list + " & ";
		} else {
			command = "cd " + reg_folder_path + "; cmtk reformatx --pad-out 0 -o Reformatted" + File.separator + "warp_" + outfilename + ".nrrd --floating " + reformat_list[i] + " " + refbrain_path + " " + transf_list + " & ";
		}
		reformatx_command = reformatx_command + command;
	}
	reformatx_command = substring(reformatx_command, 0, lastIndexOf(reformatx_command, "&"));
	return reformatx_command;
}

function affine(refbrain_path, registration_channel_path, affine_list, dof1, dof2, affine_accuracy, init_mode, init_list, affine_X, affine_reg_metric, final_res) {
	if (init_mode == "center-template") {
		affine_command = "cmtk registration --initxlate " + affine_reg_metric + " --dofs " + dof1 + " --dofs " + dof2 + " " + affine_reg_metric + " --exploration " + affine_X + " --accuracy " + affine_accuracy + " " + final_res + " -o " + affine_list + " " + refbrain_path + " " + registration_channel_path + "; ";
	} else {
		affine_command = "cmtk make_initial_affine " + init_mode + " " + refbrain_path + " " + registration_channel_path + " " + init_list + "; " +
		                 "cmtk registration --initial " + init_list + " " + affine_reg_metric + " --dofs " + dof1 + " --dofs " + dof2 + " " + affine_reg_metric + " --exploration " + affine_X + " --accuracy " + affine_accuracy + " " + final_res + " -o " + affine_list + " " + refbrain_path + " " + registration_channel_path + "; ";
	}
	return affine_command;
}

function warp(warp_list, affine_list, X, C, R, G, T, warp_accuracy, speed, warp_reg_metric, final_res) {	
	warp_command = "cmtk warp " + warp_reg_metric + " --threads " + T + " --jacobian-weight 0 " + speed + " -e " + X + " --grid-spacing " + G + " --energy-weight 1e-1 --refine " + R + " --coarsest " + C + " --ic-weight 0 --accuracy " + warp_accuracy + " " + final_res + " -o " + warp_list + " " + affine_list + ";";
	return warp_command;
}

function make_reformatx_path_list(reg_folder_path, reformat_list) {
	reformatx_path_list = newArray();
	for (i = 0; i < reformat_list.length; i++) {
		outfilename = File.getName(reformat_list[i]);
		outfilename = substring(outfilename, 0, lastIndexOf(outfilename, "."));
		if (operation == "Affine Registration") {
			reformatx_path = reg_folder_path + "/Reformatted/affine_" + outfilename + ".nrrd";
		} else {
			reformatx_path = reg_folder_path + "/Reformatted/warp_" + outfilename + ".nrrd";
		}
		reformatx_path_list = Array.concat(reformatx_path_list, reformatx_path);
	}
	return reformatx_path_list;
}

if (isOpen("Log")) {
	selectWindow("Log");
	run("Close");
}
	
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
datestamp = toString(year, 0) + "-" + toString(month, 0) + "-" + toString(dayOfMonth, 0) + "-" + toString(hour, 0) + "-" + toString(minute, 0);

images_path = image_dir + "/";
dir_list = newArray();
dir_list = Array.concat(dir_list, images_path);
directory_path_list = build_directory_path_list(images_path, dir_list);
refbrain_path = refbrain;
paralell_command_list = newArray();
name_list = newArray();
affine_check_list = newArray();
warp_check_list = newArray();
reformatx_check_list = newArray();
reformat_counter = 0;

if (res_skip)
	final_res = "--omit-original-data";
else
	final_res = "";	

if (affine_reg_metric_string == "Normalized Mutual Information")
	affine_reg_metric = "--nmi";
else if (affine_reg_metric_string == "Standard Mutual Information")
	affine_reg_metric = "--mi";
else if (affine_reg_metric_string == "Correlation Ratio")
	affine_reg_metric = "--cr";
else if (affine_reg_metric_string == "Mean Squared Difference")
	affine_reg_metric = "--msd";
else 
	affine_reg_metric = "--ncc";

if (warp_reg_metric_string == "Normalized Mutual Information")
	warp_reg_metric = "--nmi";
else if (warp_reg_metric_string == "Standard Mutual Information")
	warp_reg_metric = "--mi";
else if (warp_reg_metric_string == "Correlation Ratio")
	warp_reg_metric = "--cr";
else if (warp_reg_metric_string == "Mean Squared Difference")
	warp_reg_metric = "--msd";
else 
	warp_reg_metric = "--ncc";		

for (j = 0; j < directory_path_list.length; j++) {
	images_path = directory_path_list[j];
	imagefile_list = make_imagefile_list(images_path);
	for (i = 0; i < imagefile_list.length; i++) {
		if (matches(imagefile_list[i], ".*_01.*") == 1) {
			registration_channel = imagefile_list[i];
			name = substring(imagefile_list[i], 0, lastIndexOf(imagefile_list[i], "_"));
			name_list = Array.concat(name_list, name);	
			reg_folder_path = reg_dir + "/" + name + "_Registration_" + datestamp;
			registration_channel_path = images_path + registration_channel;
			init_list = reg_folder_path + "/" + name + "_init.list";
			affine_command = "";
			warp_command = "";
			reformatx_command = "";
	
			if ((rx1 == 1) || (rx2 == 1) || (rx3 == 1) || (rx4 == 1))
				reformat_list = make_reformat_path_list(name, imagefile_list, images_path, rx1, rx2, rx3, rx4);
	
			if (operation == "Affine Registration") {
				affine_list = reg_folder_path + "/" + name + "_affine.xform";
				affine_check_list = Array.concat(affine_check_list, affine_list);
				affine_command = affine(refbrain_path, registration_channel_path, affine_list, dof1, dof2, affine_accuracy, init_mode, init_list, affine_X, affine_reg_metric, final_res);
				transf_list = affine_list;
			}
	
			if (operation == "Affine and Warp Registration") {
				affine_list = reg_folder_path + "/" + name + "_affine.xform";
				affine_check_list = Array.concat(affine_check_list, affine_list);
				warp_list = reg_folder_path + "/" + name + "_warp.xform";
				warp_check_list = Array.concat(warp_check_list, warp_list);
				affine_command = affine(refbrain_path, registration_channel_path, affine_list, dof1, dof2, affine_accuracy, init_mode, init_list, affine_X, affine_reg_metric, final_res);
				warp_command = warp(warp_list, affine_list, X, C, R, G, T, warp_accuracy, speed, warp_reg_metric, final_res);
				transf_list = warp_list;
			}
	
			if ((rx1 == 1) || (rx2 == 1) || (rx3 == 1) || (rx4 == 1)) {
				reformatx_command = reformatx(reg_folder_path, refbrain_path, reformat_list, transf_list);
				reformatx_path_list = make_reformatx_path_list(reg_folder_path, reformat_list);
				reformatx_check_list = Array.concat(reformatx_check_list, reformatx_path_list);
			}
	
			reg_command = affine_command + warp_command + reformatx_command;
			reg_command = "(" + reg_command + ") & ";
			paralell_command_list = Array.concat(paralell_command_list, reg_command);
		}
	}
}

print("Started " + operation + " on " + paralell_command_list.length + " samples");
print("Preset: " + preset);
print(" ");

if (operation == "Affine Registration") {
	print("Affine parameters:");
	print("Initial affine method: " + init_mode);
	print("Affine registration metric: " + affine_reg_metric_string);
	print("Exploration [Initial optimizer step size]: " + affine_X);
	print("Accuracy [Final optimizer step size]: " + affine_accuracy);
	print("Degrees of freedom first pass: " + dof1);
	print("Degrees of freedom second pass: " + dof2);
	print(" ");
}

if (operation == "Affine and Warp Registration") {
	print("Affine parameters:");
	print("Initial affine method: " + init_mode);
	print("Affine registration metric: " + affine_reg_metric_string);
	print("Exploration [Initial optimizer step size]: " + affine_X);
	print("Accuracy [Final optimizer step size]: " + affine_accuracy);
	print("Degrees of freedom first pass: " + dof1);
	print("Degrees of freedom second pass: " + dof2);
	print("");
	print("Warp parameters:");
	print("Warp registration metric: " + warp_reg_metric_string);
	print("initial exploration step size: " + X);
	print("Accuracy [Final exploration step size]: " + warp_accuracy);
	print("coarsest resampling: " + C);
	print("Refine grid: " + R);
	print("grid size: " + G);
	print(" ");
}

print("Job list:");
for (i = 0; i < name_list.length; i++) {
	print(name_list[i]);
	print(paralell_command_list[i]);
	print(" ");
}

print("Please wait");

para_cycles = calc_para_cycles(paralell_command_list.length, para);
for (i = 0; i < para_cycles; i++) {
	cycle_command = "";
	if (paralell_command_list.length > para) {
		for (k = 0; k < para; k++) {
			cycle_command = cycle_command + paralell_command_list[0];
			paralell_command_list = Array.slice(paralell_command_list, 1);
		}
	} else {
		iter = paralell_command_list.length;
		for (j = 0; j < iter; j++) {
			cycle_command = cycle_command + paralell_command_list[0];
			paralell_command_list = Array.slice(paralell_command_list, 1);
		}
	}
	cycle_command = cycle_command + " wait;";
	print(cycle_command);
	exec("sh", "-c", "start_time=`date +%s`;" + cycle_command + "end_time=`date +%s`;echo execution time was `expr $end_time - $start_time` s.");
}

if (operation == "Affine and Warp Registration") {
	for (i = 0; i < warp_check_list.length; i++) {
		if (File.exists(warp_check_list[i]))
			print(name_list[i] + " Registration was successful");
		else 
			print(name_list[i] + " Registration warp failed");
		if (File.exists(affine_check_list[i]) == 0)
			print(name_list[i] + " Registration affine failed");	
	}
}

if (operation == "Affine Registration") {
	for (i = 0; i < affine_check_list.length; i++) {
		if (File.exists(affine_check_list[i]))
			print(name_list[i] + " Registration was successful");
		else 
			print(name_list[i] + " Registration affine failed");
	}		
}

for (r = 0; r < reformatx_check_list.length; r++) {
	if (File.exists(reformatx_check_list[r]))
		reformat_counter = reformat_counter + 1;
	else 
		print("Reformat failed:" + reformatx_check_list[r]);
}

print(" ");
print("Reformatted " + reformat_counter + " images");

if (avi_out) {
	setBatchMode(true);
	for (r = 0; r < reformatx_check_list.length; r++) {
		open(refbrain);
		setSlice(floor(nSlices / 2));
		run("Enhance Contrast", "saturated=0.35");
		run("8-bit");
		image = reformatx_check_list[r];
		dotIndex = lastIndexOf(image, ".");
		baseName = substring(image, 0, dotIndex);
		if (File.exists(reformatx_check_list[r]) && endsWith(baseName, "_01")) {
			exec("sh", "-c", "echo " + reformatx_check_list[r] + " NCC:; cmtk similarity " + refbrain_path + " " + reformatx_check_list[r] + " | grep 'SIMval' | awk '{print $7}'");
			logContent = getInfo("log");
			logLines = split(logContent, "\n");
			if (logLines.length > 0) {
				lastLine = logLines[logLines.length - 2];
				lastSpaceIndex = lastIndexOf(lastLine, " ");
				if (lastSpaceIndex != -1) {
					lastWord = substring(lastLine, lastSpaceIndex + 1);
				} else {
					lastWord = replace(lastLine, ".", "");
				}
			} else {
				lastWord = "Log is empty";
			}
			open(image);
			avi_path = substring(image, 0, lastIndexOf(image, "/"));
			setSlice(floor(nSlices / 2));
			run("Enhance Contrast", "saturated=0.35");
			run("8-bit");
			template_name = File.getName(refbrain);
			image_name = File.getName(image);
			run("Merge Channels...", "c2=" + template_name + " c6=" + image_name + " create ");
			run("AVI... ", "compression=JPEG frame=15 save=" + avi_path + File.separator + lastWord + "_" + image_name + "-overlay.avi");
		}
		close();
	}
	setBatchMode(false);
}

if (show == 1)
	Array.show(reformatx_check_list);

selectWindow("Log");
logdata = getInfo("log");
logpath = reg_dir + File.separator + datestamp + "_command_log.txt";
File.saveString(logdata, reg_dir + File.separator + datestamp + "_command_log.txt");

#@ String (visibility=MESSAGE, value=".", required=false) dot1
#@ String (visibility=MESSAGE, value="Written by Sandor Kovacs, sandorbx@gmail.com", required=false) msg
#@ String (visibility=MESSAGE, value="Using CMTK by Torsten Rohlfing", required=false) msg2
