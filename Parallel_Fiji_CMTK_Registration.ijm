#@ String (label= "Choose an operation to perform", choices={"Affine and Warp Registration", "Affine Registration"}, style="listBox", description="Affine and warp means a full non rigid registration, in case of suboptimal output try to run just affine and make sure it gives a good alignment") operation
#@ String (label= "Registration Parameter Preset", choices={"None", "Full Flybrain(Cachero-Ostrovksy_2010)", "VNC"}, value="None", style="listBox", description="If active will use default affine and warp parameters instead of user settings under affine and warp parameters") preset

#@ String (visibility=MESSAGE, value=" Input&Output options                                       ", required=false) io

#@ File (label = "Output directory", style = "directory") reg_dir
#@ File (label = "reference brain (file)") refbrain
#@ File (label = "images to register (directory)", description="every image file must be named like 'yourimagename_01', 'yourimagename_02', etc. The batch mode processes every scan in the folder/subfolder tree", style = "directory") image_dir
#@ boolean (label = "Show results list (double click an image to open)") show

#@ String (visibility=MESSAGE, value=" Compute options                                       ", required=false) compute_options

#@ boolean (label = "Skip final resolution step for speed", description="Skips the final resolution step in multi-level optimization, speeding up high-res images without notable quality loss") res_skip
#@ Integer (label="Number of compute threads to use", style="slider", min=1, max=160, stepSize=1, value=160) T
#@ Integer (label="Number of parallel running jobs", style="slider", min=1, max=20, stepSize=1, value=1, description="When several scans are present, processing is scheduled in parallel groups (mind your available memory)") para

#@ String (visibility=MESSAGE, value=" Reformat options                                       ", required=false) ref
#@ boolean (label = "Output overlay avi", description="Creates a quality-control overlay video from reformatted channel 01. Channel 01 is reformatted automatically when this is enabled.") avi_out
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
#@ String (label= "Compute mode", choices={"--fast", "--accurate"}, style="listBox", description="Use --accurate for slightly better results (but longer compute time)") speed
#@ boolean (label = "Output Jacobian determinant map") jacobi_out

// Presets
if (preset=="Full Flybrain(Cachero-Ostrovksy_2010)") {
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

if (preset=="VNC") {
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

// ---------- Platform and CMTK runtime ----------

function detect_platform(os_name) {
    os_lower = toLowerCase(os_name);
    if (startsWith(os_lower, "windows"))
        return "windows";
    if (startsWith(os_lower, "mac"))
        return "mac";
    if (startsWith(os_lower, "linux"))
        return "linux";
    exit("Unsupported operating system: " + os_name + "\n\nSupported platforms are Windows (CMTK in WSL), macOS, and Linux.");
}

function q(path) {
    return "'" + replace(path, "'", "'\"'\"'") + "'";
}

function normalize_folder(path) {
    if (path == "")
        return "";
    if (!endsWith(path, File.separator))
        path = path + File.separator;
    return path;
}

function direct_cmtk_runtime(bin_folder) {
    bin_folder = normalize_folder(bin_folder);
    required_tools = newArray("make_initial_affine", "registration", "warp", "reformatx", "similarity");
    for (t = 0; t < required_tools.length; t++) {
        if (!File.isFile(bin_folder + required_tools[t]))
            return "";
    }
    return "direct|" + bin_folder;
}

function cmtk_runtime_from_folder(folder) {
    folder = normalize_folder(folder);
    if (folder == "")
        return "";

    if (File.isFile(folder + "cmtk"))
        return "launcher|" + folder + "cmtk";

    runtime = direct_cmtk_runtime(folder);
    if (runtime != "")
        return runtime;

    if (File.isFile(folder + "bin" + File.separator + "cmtk"))
        return "launcher|" + folder + "bin" + File.separator + "cmtk";

    runtime = direct_cmtk_runtime(folder + "bin");
    if (runtime != "")
        return runtime;

    runtime = direct_cmtk_runtime(folder + "lib" + File.separator + "cmtk" + File.separator + "bin");
    if (runtime != "")
        return runtime;

    local_prefix = folder + "usr" + File.separator + "local" + File.separator;
    if (File.isFile(local_prefix + "bin" + File.separator + "cmtk"))
        return "launcher|" + local_prefix + "bin" + File.separator + "cmtk";

    runtime = direct_cmtk_runtime(local_prefix + "lib" + File.separator + "cmtk" + File.separator + "bin");
    if (runtime != "")
        return runtime;

    runtime = direct_cmtk_runtime(local_prefix + "bin");
    if (runtime != "")
        return runtime;

    usr_prefix = folder + "usr" + File.separator;
    if (File.isFile(usr_prefix + "bin" + File.separator + "cmtk"))
        return "launcher|" + usr_prefix + "bin" + File.separator + "cmtk";

    runtime = direct_cmtk_runtime(usr_prefix + "lib" + File.separator + "cmtk" + File.separator + "bin");
    if (runtime != "")
        return runtime;

    return "" + direct_cmtk_runtime(usr_prefix + "bin");
}

function cmtk_tool_from_runtime(runtime, tool) {
    separator = indexOf(runtime, "|");
    mode = substring(runtime, 0, separator);
    path = substring(runtime, separator + 1);
    if (mode == "launcher")
        return "" + q(path) + " " + tool;
    return "" + q("" + normalize_folder(path) + tool);
}

function cmtk_tool(tool) {
    if (platform == "windows")
        return "cmtk " + tool;
    return "" + cmtk_tool_from_runtime(cmtk_runtime, tool);
}

function runtime_probe(runtime) {
    required_tools = newArray("make_initial_affine", "registration", "warp", "reformatx", "similarity");
    for (t = 0; t < required_tools.length; t++) {
        tool_command = cmtk_tool_from_runtime(runtime, required_tools[t]);
        probe_status = trim(exec("sh", "-c", tool_command + " --version >/dev/null 2>&1; echo $?"));
        if (probe_status != "0")
            return 0;
    }
    return 1;
}

function validate_posix_cmtk(runtime) {
    required_tools = newArray("make_initial_affine", "registration", "warp", "reformatx", "similarity");
    system_arch = trim(exec("uname", "-m"));
    if (system_arch == "")
        system_arch = "unknown";

    for (t = 0; t < required_tools.length; t++) {
        tool_command = cmtk_tool_from_runtime(runtime, required_tools[t]);
        probe_status = trim(exec("sh", "-c", tool_command + " --version >/dev/null 2>&1; echo $?"));
        if (probe_status != "0") {
            probe_output = trim(exec("sh", "-c", tool_command + " --version 2>&1"));
            if (probe_output == "")
                probe_output = "No diagnostic output was returned.";
            exit("CMTK validation failed for '" + required_tools[t] + "'.\n\nOperating system: " + os_name + "\nArchitecture: " + system_arch + "\nCMTK location: " + substring(runtime, indexOf(runtime, "|") + 1) + "\n\nCMTK output:\n" + probe_output + "\n\nCheck that this is a complete CMTK installation built for this system and that the executables are allowed to run.");
        }
    }

    print("CMTK validated: " + substring(runtime, indexOf(runtime, "|") + 1));
    print("System architecture: " + system_arch);
}

function first_valid_launcher(candidates) {
    for (c = 0; c < candidates.length; c++) {
        if (File.isFile(candidates[c])) {
            runtime = "launcher|" + candidates[c];
            if (runtime_probe(runtime))
                return runtime;
            print("Skipping unusable CMTK candidate: " + candidates[c]);
        }
    }
    return "";
}

function first_valid_direct_bin(candidates) {
    for (c = 0; c < candidates.length; c++) {
        runtime = direct_cmtk_runtime(candidates[c]);
        if (runtime != "") {
            if (runtime_probe(runtime))
                return runtime;
            print("Skipping unusable CMTK candidate: " + candidates[c]);
        }
    }
    return "";
}

function resolve_posix_cmtk() {
    runtime = "";

    launcher = trim(exec("sh", "-c", "command -v cmtk 2>/dev/null || true"));
    if (launcher != "" && File.isFile(launcher)) {
        candidate = "launcher|" + launcher;
        if (runtime_probe(candidate))
            runtime = candidate;
        else
            print("Skipping unusable CMTK candidate from PATH: " + launcher);
    }

    if (runtime == "") {
        reformatx_path = trim(exec("sh", "-c", "command -v reformatx 2>/dev/null || true"));
        if (reformatx_path != "" && File.isFile(reformatx_path)) {
            candidate = direct_cmtk_runtime(File.getDirectory(reformatx_path));
            if (candidate != "" && runtime_probe(candidate))
                runtime = candidate;
            else if (candidate != "")
                print("Skipping unusable direct CMTK tools from PATH: " + File.getDirectory(reformatx_path));
        }
    }

    if (runtime == "" && platform == "mac") {
        launcher_candidates = newArray("/usr/local/bin/cmtk", "/opt/homebrew/bin/cmtk", "/opt/local/bin/cmtk");
        runtime = first_valid_launcher(launcher_candidates);
    }

    if (runtime == "" && platform == "mac") {
        bin_candidates = newArray("/usr/local/lib/cmtk/bin", "/usr/local/bin", "/opt/homebrew/lib/cmtk/bin", "/opt/homebrew/bin", "/opt/local/lib/cmtk/bin", "/opt/local/bin", "/Applications/IGSRegistrationTools/bin");
        runtime = first_valid_direct_bin(bin_candidates);
    }

    if (runtime == "" && platform == "linux") {
        launcher_candidates = newArray("/usr/bin/cmtk", "/usr/local/bin/cmtk");
        runtime = first_valid_launcher(launcher_candidates);
    }

    if (runtime == "" && platform == "linux") {
        bin_candidates = newArray("/usr/lib/cmtk/bin", "/usr/local/lib/cmtk/bin", "/usr/bin", "/usr/local/bin");
        runtime = first_valid_direct_bin(bin_candidates);
    }

    if (runtime == "") {
        cmtk_folder = getDirectory("Choose the CMTK installation or binary folder");
        runtime = cmtk_runtime_from_folder(cmtk_folder);
        if (runtime == "")
            exit("CMTK was not found in the selected folder.\n\nChoose the CMTK installation root, the folder containing the 'cmtk' launcher, or the folder containing make_initial_affine, registration, warp, reformatx and similarity.");
    }

    validate_posix_cmtk(runtime);
    return runtime;
}

function validate_wsl_cmtk() {
    required_tools = newArray("make_initial_affine", "registration", "warp", "reformatx", "similarity");
    for (t = 0; t < required_tools.length; t++) {
        tool = required_tools[t];
        probe_status = trim(exec("wsl", "sh", "-lc", "cmtk " + tool + " --version >/dev/null 2>&1; echo $?"));
        if (probe_status != "0") {
            probe_output = trim(exec("wsl", "sh", "-lc", "cmtk " + tool + " --version 2>&1"));
            if (probe_output == "")
                probe_output = "No diagnostic output was returned.";
            exit("WSL/CMTK validation failed for '" + tool + "'.\n\nCMTK must be installed in the default WSL distribution.\nFor Ubuntu: sudo apt install cmtk\n\nCMTK output:\n" + probe_output);
        }
    }
    print("WSL/CMTK validated");
}

function path_translate_windows(winpath) {
    if (lengthOf(winpath) < 3 || substring(winpath, 1, 2) != ":")
        exit("Windows WSL mode requires a drive-letter path such as C:/data/image.nrrd. Unsupported path: " + winpath);
    drive = toLowerCase(substring(winpath, 0, 1));
    path = substring(winpath, 2);
    linuxpath = replace(path, File.separator, "/");
    return "/mnt/" + drive + linuxpath;
}

function cmtk_path(native_path) {
    if (platform == "windows")
        return "" + path_translate_windows(native_path);
    return native_path;
}

function run_shell_script(script_text, log_dir, datestamp) {
    command_file = log_dir + File.separator + datestamp + "_command.sh";
    File.saveString(script_text, command_file);

    if (platform == "windows") {
        command_path = cmtk_path(command_file);
        shell_output = exec("wsl", "bash", command_path);
    } else {
        shell_output = exec("sh", command_file);
    }
    return shell_output;
}

function run_similarity(refbrain_cmtk, image_native) {
    image_cmtk = cmtk_path(image_native);
    command = "" + cmtk_tool("similarity") + " " + q(refbrain_cmtk) + " " + q(image_cmtk) + " 2>&1";
    if (platform == "windows")
        similarity_output = exec("wsl", "sh", "-lc", command);
    else
        similarity_output = exec("sh", "-c", command);
    return similarity_output;
}

// ---------- Shared registration engine ----------

function extract_simval(output) {
    lines = split(output, "\n");
    for (s = 0; s < lines.length; s++) {
        if (indexOf(lines[s], "SIMval") >= 0) {
            fields = split(trim(lines[s]));
            if (fields.length >= 7)
                return fields[6];
        }
    }
    return "";
}

function unique_sample_id(name, used_names) {
    candidate = name;
    suffix = 2;
    found = 1;
    while (found) {
        found = 0;
        for (u = 0; u < used_names.length; u++) {
            if (used_names[u] == candidate)
                found = 1;
        }
        if (found) {
            candidate = name + "_" + suffix;
            suffix = suffix + 1;
        }
    }
    return candidate;
}

function calc_para_cycles(length, para) {
    a = length / para;
    r = length % para;
    if (r != 0) {
        a = substring(a, 0, lastIndexOf(a, "."));
        a = parseInt(a);
        a = a + 1;
    }
    return a;
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
    for (i = 0; i < imagefile_list.length; i++) {
        base = File.getNameWithoutExtension(imagefile_list[i]);
        if (rx1 == 1 && base == name + "_01")
            reformat_list = Array.concat(reformat_list, images_path + imagefile_list[i]);
        if (rx2 == 1 && base == name + "_02")
            reformat_list = Array.concat(reformat_list, images_path + imagefile_list[i]);
        if (rx3 == 1 && base == name + "_03")
            reformat_list = Array.concat(reformat_list, images_path + imagefile_list[i]);
        if (rx4 == 1 && base == name + "_04")
            reformat_list = Array.concat(reformat_list, images_path + imagefile_list[i]);
    }
    return reformat_list;
}

function make_imagefile_list(image_dir) {
    list = getFileList(image_dir);
    list = Array.sort(list);
    image_list = newArray();
    for (i = 0; i < list.length; i++) {
        lower = toLowerCase(list[i]);
        if (endsWith(lower, ".nrrd") || endsWith(lower, ".pic") || endsWith(lower, ".nii"))
            image_list = Array.concat(image_list, list[i]);
    }
    return image_list;
}

function reformatx(reg_folder_cmtk, refbrain_cmtk, reformat_list_cmtk, transf_list_cmtk) {
    reformatx_command = "cd " + q(reg_folder_cmtk) + "; mkdir -p Reformatted; ";
    for (i = 0; i < reformat_list_cmtk.length; i++) {
        outfilename = File.getNameWithoutExtension(reformat_list_cmtk[i]);
        if (operation == "Affine Registration") {
            command = "" + cmtk_tool("reformatx") + " --pad-out 0 -o " + q("Reformatted/affine_" + outfilename + ".nrrd") + " --floating " + q(reformat_list_cmtk[i]) + " " + q(refbrain_cmtk) + " " + q(transf_list_cmtk) + "; ";
        } else if (jacobi_out == 1 && endsWith(outfilename, "_01")) {
            command = "" + cmtk_tool("reformatx") + " --jacobian-correct-global --pad-out 0 -o " + q("Reformatted/jacobian_warp_" + outfilename + ".nrrd") + " " + q(refbrain_cmtk) + " --jacobian " + q(transf_list_cmtk) + "; " +
                      cmtk_tool("reformatx") + " --pad-out 0 -o " + q("Reformatted/warp_" + outfilename + ".nrrd") + " --floating " + q(reformat_list_cmtk[i]) + " " + q(refbrain_cmtk) + " " + q(transf_list_cmtk) + "; ";
        } else {
            command = "" + cmtk_tool("reformatx") + " --pad-out 0 -o " + q("Reformatted/warp_" + outfilename + ".nrrd") + " --floating " + q(reformat_list_cmtk[i]) + " " + q(refbrain_cmtk) + " " + q(transf_list_cmtk) + "; ";
        }
        reformatx_command = reformatx_command + command;
    }
    return reformatx_command;
}

function affine(refbrain_cmtk, registration_channel_cmtk, affine_list_cmtk, dof1, dof2, affine_accuracy, init_mode, init_list_cmtk, affine_X, affine_reg_metric, final_res) {
    if (init_mode == "center-template") {
        affine_command = "" + cmtk_tool("registration") + " --initxlate " + affine_reg_metric + " --dofs " + dof1 + " --dofs " + dof2 + " " + affine_reg_metric + " --exploration " + affine_X + " --accuracy " + affine_accuracy + " " + final_res + " -o " + q(affine_list_cmtk) + " " + q(refbrain_cmtk) + " " + q(registration_channel_cmtk) + "; ";
    } else {
        affine_command = "" + cmtk_tool("make_initial_affine") + " " + init_mode + " " + q(refbrain_cmtk) + " " + q(registration_channel_cmtk) + " " + q(init_list_cmtk) + "; " +
                         cmtk_tool("registration") + " --initial " + q(init_list_cmtk) + " " + affine_reg_metric + " --dofs " + dof1 + " --dofs " + dof2 + " " + affine_reg_metric + " --exploration " + affine_X + " --accuracy " + affine_accuracy + " " + final_res + " -o " + q(affine_list_cmtk) + " " + q(refbrain_cmtk) + " " + q(registration_channel_cmtk) + "; ";
    }
    return affine_command;
}

function warp(warp_list_cmtk, affine_list_cmtk, X, C, R, G, T, warp_accuracy, speed, warp_reg_metric, final_res) {
    warp_command = "" + cmtk_tool("warp") + " " + warp_reg_metric + " --threads " + T + " --jacobian-weight 0 " + speed + " -e " + X + " --grid-spacing " + G + " --energy-weight 1e-1 --refine " + R + " --coarsest " + C + " --ic-weight 0 --accuracy " + warp_accuracy + " " + final_res + " -o " + q(warp_list_cmtk) + " " + q(affine_list_cmtk) + ";";
    return warp_command;
}

function make_reformatx_path_list(reg_folder_native, reformat_list_native) {
    reformatx_path_list = newArray();
    for (i = 0; i < reformat_list_native.length; i++) {
        outfilename = File.getNameWithoutExtension(reformat_list_native[i]);
        if (operation == "Affine Registration")
            reformatx_path = reg_folder_native + File.separator + "Reformatted" + File.separator + "affine_" + outfilename + ".nrrd";
        else
            reformatx_path = reg_folder_native + File.separator + "Reformatted" + File.separator + "warp_" + outfilename + ".nrrd";
        reformatx_path_list = Array.concat(reformatx_path_list, reformatx_path);
    }
    return reformatx_path_list;
}

// ---------- Main ----------

if (isOpen("Log")) {
    selectWindow("Log");
    run("Close");
}

os_name = getInfo("os.name");
platform = detect_platform(os_name);
print("Detected operating system: " + os_name + " (" + platform + ")");

cmtk_runtime = "";
if (platform == "windows")
    validate_wsl_cmtk();
else
    cmtk_runtime = resolve_posix_cmtk();

if (avi_out)
    rx1 = 1;

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
datestamp = toString(year, 0) + "-" + toString(month + 1, 0) + "-" + toString(dayOfMonth, 0) + "-" + toString(hour, 0) + "-" + toString(minute, 0) + "-" + toString(second, 0);

images_path_native = image_dir + File.separator;
dir_list = newArray();
dir_list = Array.concat(dir_list, images_path_native);
directory_path_list = build_directory_path_list(images_path_native, dir_list);
refbrain_cmtk = cmtk_path(refbrain);
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
    images_path_native = directory_path_list[j];
    images_path_cmtk = cmtk_path(images_path_native);
    imagefile_list = make_imagefile_list(images_path_native);

    for (i = 0; i < imagefile_list.length; i++) {
        base_name = File.getNameWithoutExtension(imagefile_list[i]);
        if (endsWith(base_name, "_01")) {
            name = substring(base_name, 0, lastIndexOf(base_name, "_01"));
            sample_id = unique_sample_id(name, name_list);
            name_list = Array.concat(name_list, sample_id);

            reg_folder_native = reg_dir + File.separator + sample_id + "_Registration_" + datestamp;
            reg_folder_cmtk = cmtk_path(reg_folder_native);
            registration_channel_native = images_path_native + imagefile_list[i];
            registration_channel_cmtk = cmtk_path(registration_channel_native);
            init_list_native = reg_folder_native + File.separator + sample_id + "_init.list";
            init_list_cmtk = cmtk_path(init_list_native);
            affine_command = "";
            warp_command = "";
            reformatx_command = "";

            if ((rx1 == 1) || (rx2 == 1) || (rx3 == 1) || (rx4 == 1)) {
                reformat_list_cmtk = make_reformat_path_list(name, imagefile_list, images_path_cmtk, rx1, rx2, rx3, rx4);
                reformat_list_native = make_reformat_path_list(name, imagefile_list, images_path_native, rx1, rx2, rx3, rx4);
            }

            if (operation == "Affine Registration") {
                affine_list_native = reg_folder_native + File.separator + sample_id + "_affine.xform";
                affine_check_list = Array.concat(affine_check_list, affine_list_native);
                affine_list_cmtk = cmtk_path(affine_list_native);
                affine_command = affine(refbrain_cmtk, registration_channel_cmtk, affine_list_cmtk, dof1, dof2, affine_accuracy, init_mode, init_list_cmtk, affine_X, affine_reg_metric, final_res);
                transf_list_cmtk = affine_list_cmtk;
            }

            if (operation == "Affine and Warp Registration") {
                affine_list_native = reg_folder_native + File.separator + sample_id + "_affine.xform";
                warp_list_native = reg_folder_native + File.separator + sample_id + "_warp.xform";
                affine_check_list = Array.concat(affine_check_list, affine_list_native);
                warp_check_list = Array.concat(warp_check_list, warp_list_native);
                affine_list_cmtk = cmtk_path(affine_list_native);
                warp_list_cmtk = cmtk_path(warp_list_native);
                affine_command = affine(refbrain_cmtk, registration_channel_cmtk, affine_list_cmtk, dof1, dof2, affine_accuracy, init_mode, init_list_cmtk, affine_X, affine_reg_metric, final_res);
                warp_command = warp(warp_list_cmtk, affine_list_cmtk, X, C, R, G, T, warp_accuracy, speed, warp_reg_metric, final_res);
                transf_list_cmtk = warp_list_cmtk;
            }

            if ((rx1 == 1) || (rx2 == 1) || (rx3 == 1) || (rx4 == 1)) {
                reformatx_command = reformatx(reg_folder_cmtk, refbrain_cmtk, reformat_list_cmtk, transf_list_cmtk);
                reformatx_path_list = make_reformatx_path_list(reg_folder_native, reformat_list_native);
                reformatx_check_list = Array.concat(reformatx_check_list, reformatx_path_list);
            }

            reg_command = "mkdir -p " + q(reg_folder_cmtk) + "; " + affine_command + warp_command + reformatx_command;
            reg_command = "(set -e; " + reg_command + ") & ";
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
bash_command = "";
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
    bash_command = bash_command + cycle_command + "wait; ";
}

script_text = "exec 2>&1\nstart_time=$(date +%s);\n" + bash_command + "\nend_time=$(date +%s); echo execution time was $((end_time-start_time)) s;\n";
run_output = run_shell_script(script_text, reg_dir, datestamp);
print(run_output);

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
        print("Reformat failed: " + reformatx_check_list[r]);
}

print(" ");
print("Reformatted " + reformat_counter + " images");

if (avi_out) {
    setBatchMode(true);
    for (r = 0; r < reformatx_check_list.length; r++) {
        image = reformatx_check_list[r];
        if (File.exists(image) && endsWith(File.getNameWithoutExtension(image), "_01")) {
            qc_output = run_similarity(refbrain_cmtk, image);
            qc_score = extract_simval(qc_output);
            if (qc_score == "") {
                qc_score = "NA";
                print(File.getName(image) + " QC similarity could not be parsed. CMTK output:");
                print(qc_output);
            } else {
                print(File.getName(image) + " QC similarity: " + qc_score);
            }

            ref_title = "QC_reference_" + r;
            reg_title = "QC_registered_" + r;
            open(refbrain);
            rename(ref_title);
            setSlice(floor(nSlices / 2));
            run("Enhance Contrast", "saturated=0.35");
            run("8-bit");

            open(image);
            rename(reg_title);
            setSlice(floor(nSlices / 2));
            run("Enhance Contrast", "saturated=0.35");
            run("8-bit");

            run("Merge Channels...", "c2=" + ref_title + " c6=" + reg_title + " create keep");
            avi_path = File.getDirectory(image);
            video_name = "SIM_" + qc_score + "_" + File.getNameWithoutExtension(image) + "-overlay.avi";
            run("AVI... ", "compression=JPEG frame=15 save=[" + avi_path + video_name + "]");
            close();
            selectWindow(reg_title);
            close();
            selectWindow(ref_title);
            close();
        }
    }
    setBatchMode(false);
}

if (show == 1)
    Array.show(reformatx_check_list);

selectWindow("Log");
logdata = getInfo("log");
File.saveString(logdata, reg_dir + File.separator + datestamp + "_command_log.txt");

#@ String (visibility=MESSAGE, value=".", required=false) dot1
#@ String (visibility=MESSAGE, value="Written by Sandor Kovacs, sandorbx@gmail.com", required=false) msg
#@ String (visibility=MESSAGE, value="Using CMTK by Torsten Rohlfing", required=false) msg2