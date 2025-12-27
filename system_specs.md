# System Hardware & Software Specifications

**Generated:** 2025-12-25  
**Machine:** Lenovo ideapad 320-15ABR  
**Machine ID:** 08c94271f8bf467b9eea17398d51953e

---

## Hardware Specifications

### CPU (Processor)
- **Model:** AMD A12-9720P RADEON R7, 12 COMPUTE CORES 4C+8G
- **Vendor:** AuthenticAMD
- **Architecture:** x86_64 (64-bit)
- **Physical Cores:** 2
- **Logical Cores/Threads:** 4 (2 threads per core)
- **Socket(s):** 1
- **Frequency Range:** 1.4 GHz (min) - 2.7 GHz (max)
- **Cache:**
  - L1d: 128 KiB (4 instances)
  - L1i: 192 KiB (2 instances)
  - L2: 2 MiB (2 instances)
- **Virtualization:** AMD-V supported
- **Instruction Sets:** AVX, AVX2, SSE4.1/4.2, AES-NI, FMA, FMA4, BMI1, BMI2, and more

### GPU (Graphics)
- **Model:** AMD Radeon R5/R6/R7 Graphics (Wani/Carrizo)
- **Type:** Integrated GPU (part of APU)
- **Subsystem:** Lenovo Wani [Radeon R5/R6/R7 Graphics]
- **Revision:** c8
- **Kernel Driver:** amdgpu
- **Memory:** 256 MB prefetchable + 8 MB prefetchable
- **OpenGL Version:** 4.6 (Compatibility Profile)
- **OpenGL Shading Language:** 4.60
- **OpenGL Vendor:** AMD
- **OpenGL Renderer:** AMD Radeon R7 Graphics (carrizo, LLVM 15.0.7, DRM 3.57)
- **Driver:** Mesa 23.2.1-1ubuntu3.1~22.04.3

### Memory (RAM)
- **Total Capacity:** 7,680 MiB (7.5 GB)
- **Swap Total:** 2,097,148 kB (2.0 GB)

### Storage
- **Primary Drive:** 931.5 GB (sda)
  - **Partition 1 (sda1):** 512 MB - /boot/efi (vfat)
  - **Partition 2 (sda2):** 931 GB - / (ext4)
- **Optical Drive:** DVD-RW DA8AESH (sr0) - 1024 MB

### Display
- **Device:** /dev/fb0
- **Model:** Wani [Radeon R5/R6/R7 Graphics]

---

## Software Specifications

### Operating System
- **OS:** Ubuntu 22.04.5 LTS (Jammy Jellyfish)
- **Kernel:** Linux 6.8.0-90-generic
- **Kernel Build:** x86_64-linux-gnu-gcc-12 (Ubuntu 12.3.0-1ubuntu1~22.04.2)
- **Architecture:** x86-64
- **Boot ID:** e7d45d7a354f4fffa01feaee4c942eea

### Graphics Drivers & Libraries
- **Mesa Version:** 23.2.1-1ubuntu3.1~22.04.3
- **X Server:** 21.1.4-2ubuntu1.7~22.04.16
- **AMDGPU Driver:** 22.0.0-1ubuntu0.2
- **Radeon Driver:** 19.1.0-2ubuntu1
- **LLVM Version:** 15.0.7
- **DRM Version:** 3.57

### Key Development Tools Installed
- **Python:** 3.10.12 (with dev packages)
- **GCC:** 12.3.0-1ubuntu1~22.04.2
- **Git:** (installed via standard packages)
- **Build Tools:** make, cmake, build-essential packages
- **Qt5:** 5.15.3 (multiple Qt5 libraries installed)
- **OpenGL Libraries:** libopengl0, libgl1-mesa-glx, libgl1, etc.

### Graphics & Multimedia Libraries
- **OpenGL:** libopengl0, libgl1-mesa-glx, libgl1, libglu1-mesa
- **Vulkan:** (if installed, check with `vulkaninfo`)
- **Video Acceleration:** va-driver-all, vdpau-driver-all
- **GStreamer:** (installed via multimedia packages)
- **FFmpeg:** 4.4.2-0ubuntu0.22.04.1

### Desktop Environment
- **DE:** GNOME (Unity-based)
- **Display Server:** X11 (with Wayland support via xwayland)
- **Window Manager:** Unity/GNOME Shell

### Development Environment Notes
- **Godot:** Not found in system PATH (may be installed via snap/flatpak or custom location)
- **Blender:** Installed via snap (versions 6810, 6898)
- **FreeCAD:** Installed via snap (versions 1248, 1634)
- **Inkscape:** Installed via snap (versions 10758, 10823)

### Package Management
- **Package Manager:** APT (dpkg)
- **Snap Support:** Enabled (snapd 2.72+ubuntu22.04)
- **Package Count:** Extensive standard Ubuntu 22.04 LTS installation

### Network & System Services
- **Network Manager:** Installed and active
- **Systemd:** 249.11-0ubuntu3.16
- **PulseAudio:** 15.99.1+dfsg1-1ubuntu2.2
- **PipeWire:** 0.3.48-1ubuntu3 (audio/video processing)

### Security & Virtualization
- **Secure Boot:** shim-signed 1.51.4+15.8-0ubuntu1
- **Virtualization Support:** AMD-V enabled in CPU
- **Container Support:** Docker/containerd (if installed separately)

---

## Performance Characteristics

### CPU Performance Class
- **Category:** Entry-level APU
- **Use Case:** Light gaming, general computing, development work
- **Limitations:** May struggle with heavy 3D workloads, complex procedural generation, or high-poly model rendering

### GPU Performance Class
- **Category:** Integrated graphics (entry-level)
- **OpenGL Support:** Full OpenGL 4.6 compatibility
- **Use Case:** Basic 3D rendering, 2D graphics, video playback
- **Limitations:** Limited VRAM (256 MB dedicated), may struggle with:
  - Complex shaders
  - High-resolution textures
  - Multiple light sources
  - Large procedural terrain chunks
  - Real-time shadows at high quality

### Memory Characteristics
- **Total:** 7.5 GB (adequate for development, may need optimization for large projects)
- **Swap:** 2 GB (standard for Ubuntu installation)

### Storage Characteristics
- **Type:** Traditional HDD (931 GB capacity)
- **File System:** ext4
- **Performance:** Standard HDD speeds (not SSD)

---

## Recommendations for Genesis Mythos Development

### Performance Optimization
1. **Use lower quality settings** for initial development and testing
2. **Limit procedural terrain chunk size** to reduce memory/GPU load
3. **Optimize texture sizes** (use compressed formats, lower resolutions)
4. **Reduce shadow quality** and limit dynamic lights
5. **Test frequently** on this hardware to ensure playability

### Development Workflow
1. **Monitor memory usage** during development (7.5 GB can fill quickly)
2. **Close unnecessary applications** when running Godot
3. **Use Godot's built-in profiler** to identify bottlenecks
4. **Consider LOD (Level of Detail)** systems for 3D models
5. **Test on this hardware regularly** to ensure target performance

### System Maintenance
1. **Keep Mesa drivers updated** for best OpenGL performance
2. **Monitor swap usage** - high swap usage indicates memory pressure
3. **Consider upgrading RAM** if budget allows (8 GB minimum recommended for game development)
4. **SSD upgrade** would significantly improve load times and general system responsiveness

---

## Notes

- This system meets minimum requirements for Godot 4.5.1 development
- Integrated GPU should handle basic 3D scenes but may struggle with complex procedural terrain
- System is suitable for development but may require optimization for end-user experience
- All hardware is properly detected and drivers are installed
- OpenGL 4.6 support is confirmed, which is required for Godot 4.x

