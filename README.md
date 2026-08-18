## Installation instructions

Use the same Fiji macro on all supported platforms:

`Parallel_Fiji_CMTK_Registration.ijm`

The macro detects the operating system with ImageJ's `getInfo("os.name")` and selects the corresponding CMTK runtime automatically:

- **Windows 10/11:** CMTK runs inside the default WSL distribution.
- **macOS:** CMTK runs natively and is discovered from `PATH`, standard installation locations, or a user-selected CMTK folder when automatic discovery fails.
- **Linux:** CMTK runs natively and is discovered from `PATH`, standard installation locations, or a user-selected CMTK folder when automatic discovery fails.

The registration, reformatting, batching, result checks, and QC code are shared across all platforms. Only CMTK discovery, path translation, and process launching are platform-specific.

If you don't have it already, install Fiji from https://fiji.sc. Place `Parallel_Fiji_CMTK_Registration.ijm` in your `fiji.app/plugins/macros` directory and start it from the **Plugins > Macros** menu, or drag and drop the script onto the Fiji window.

### Linux (Ubuntu/Debian)

Open a Terminal and install CMTK from the repository:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install cmtk -y
```

The macro validates `make_initial_affine`, `registration`, `warp`, `reformatx`, and `similarity` with CMTK's global `--version` option before registration starts. It first checks `PATH` and common `/usr`/`/usr/local` locations. If no working installation is found, it asks for the CMTK installation or binary folder.

### macOS

CMTK installation differs between Apple Silicon and older Intel Macs. The macro reports the detected system architecture during CMTK validation.

#### Apple Silicon (M1/M2/M3/M4 and later)

The most current prebuilt option is the automated arm64 build from Greg Jefferis' CMTK `natdev` branch:

https://github.com/jefferis/cmtk/releases/tag/natdev-latest

Download the macOS arm64 `.pkg` (`cmtk-3.4.0-dev-macos-arm64-gcd.pkg`) and install it. This is a rolling prerelease build rather than the stable NITRC release. The automated build targets macOS 12 or newer and installs CMTK under `/usr/local`.

The package installs the `cmtk` launcher at `/usr/local/bin/cmtk` and the actual command-line tools under `/usr/local/lib/cmtk/bin`. The macro checks both locations directly, so Finder-launched Fiji does not need to inherit `/usr/local/bin` in its shell `PATH`.

#### Intel Mac

The current automated `natdev-latest` release does not provide a macOS x86_64 package. NITRC provides a contributed CMTK 3.4.0 macOS zip, but its download entry does not identify the CPU architecture. You can try that package and let the macro's per-tool validation determine whether it runs on the Intel Mac, or build CMTK from source if it is incompatible:

https://www.nitrc.org/frs/download.php/19547/CMTK-3.4.0-contrib-MacOSX.zip

Keep an extracted CMTK distribution in a permanent location. The old CMTK 3.3.1 macOS 10.6 DMG is obsolete for current macOS versions.

#### macOS discovery and validation

The macro checks the shell `PATH`, `/usr/local`, Homebrew/MacPorts-style locations, and the historical IGS Registration Tools location. Candidate installations are not accepted merely because files exist: all required CMTK tools are executed with `--version` before registration starts.

If no usable installation is found automatically, the macro asks you to choose the CMTK installation or binary folder. You may select an installation root, the folder containing the `cmtk` launcher, the direct CMTK binary folder, or an extracted package tree containing `usr/local/...`.

If validation fails, the macro reports the operating system, architecture, CMTK location, exact failing tool, and diagnostic output. This should distinguish an incomplete installation, architecture mismatch, missing dependency, and macOS execution/security block.

macOS may block software downloaded outside the App Store when it is not signed/notarized. Do not disable Gatekeeper globally. If you trust the CMTK package and macOS blocks it, first attempt to open/install it, then use **System Settings > Privacy & Security > Open Anyway** as described by Apple.

### Windows 10/11

Make sure Windows is up to date. Start PowerShell as administrator and install WSL:

```powershell
wsl --install
```

Install an Ubuntu distribution under WSL if one is not already available. Then open Ubuntu/WSL and install CMTK:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install cmtk -y
```

The macro runs CMTK through the **default WSL distribution** and validates `make_initial_affine`, `registration`, `warp`, `reformatx`, and `similarity` before registration starts.

Fiji continues to use native Windows paths for file access and result checks. Only paths passed to CMTK are translated to the WSL namespace; for example `C:\data\brain.nrrd` becomes `/mnt/c/data/brain.nrrd`. UNC paths such as `\\server\share\...` are not supported by the Windows/WSL runtime.

## User guide

- Registration accepts `.nrrd`, `.nii`, and `.PIC`/`.pic` image files. Conversion can be done in Fiji/ImageJ when needed.

- Paths containing ordinary spaces are supported. Standard file and directory names are still recommended for portability between Fiji, the host operating system, and CMTK.

- Image channels must use the naming convention `yourpicturename_01`, `yourpicturename_02`, and so on. `_01` is the registration channel. Images belonging to the same scan must have identical base names and differ only in the channel suffix.

- The script has an automatic batch mode. The **images to register** directory is scanned recursively, so a complete directory tree can be processed in one run. If the same sample basename occurs in more than one directory, output names are made unique automatically rather than being written into the same registration folder.

- You can set the number of parallel sample jobs. Keep available memory in mind. Reformatting of the selected channels within each sample is completed sequentially so result checks and quality control do not race unfinished output files.

- **Output overlay avi** creates a quality-control overlay from channel 01. When enabled, channel 01 is reformatted automatically even if its reformat checkbox was not selected. The macro calculates the CMTK `similarity` value from the reformatted channel, writes the value to the Fiji log, and includes it in the AVI filename as `SIM_<value>_...-overlay.avi`.

- **Output Jacobian determinant map** generates the Jacobian map with `reformatx --jacobian` and `--jacobian-correct-global` for the channel-01 warp output.

- Each run writes a shell command file and Fiji command log to the selected output directory. Timestamps include seconds to reduce accidental output-directory collisions between repeated runs.

- If you check **Show results list**, reformatted images are displayed in a list that can be double-clicked to open an image.

- For detailed information on CMTK registration parameters and operations, see the flybrain warping documentation: http://flybrain.mrc-lmb.cam.ac.uk/dokuwiki/doku.php?id=warping_manual:start

### Special thanks to

Kei Ito, Gregory Jefferis, Hideo Otsuna and Takashi Kawase