# TensorFlow Build Dependencies Summary

## Updated Dependencies (June 2025)

### Core Versions
- **TensorFlow**: 2.19.0 (latest stable)
- **Bazelisk**: 1.26.0 (latest)
- **NumPy**: 2.2.6 (latest compatible)
- **Six**: 1.17.0 (latest)

### System Dependencies

#### Essential Build Tools
- `curl` - Download Bazelisk and other resources
- `git` - Clone TensorFlow repository
- `pip` - Python package management
- `build-essential` - GCC, make, and other compilation tools
- `patchelf` - ELF binary modification (required by TensorFlow)
- `python3-full` - Complete Python installation
- `python3-dev` - Python development headers
- `python3-distutils` - Python distribution utilities
- `python3-venv` - Virtual environment support

#### Mathematical Libraries (NEW)
- `libomp-dev` - OpenMP for parallel processing
- `libopenblas-dev` - Optimized BLAS implementation
- `liblapack-dev` - Linear Algebra PACKage
- `libeigen3-dev` - C++ template library for linear algebra
- `libblas-dev` - Basic Linear Algebra Subprograms
- `libatlas-base-dev` - Automatically Tuned Linear Algebra Software

#### System Tools
- `cpuinfo` - CPU information utility (for core count detection)
- `llvm-17` - LLVM compiler infrastructure
- `clang-17` - Clang C/C++ compiler

### New Features

#### OS Version Checking
- Automatic detection of Ubuntu/Debian versions
- Compatibility validation (Ubuntu 20.04+ recommended)
- User confirmation for unsupported systems

#### Enhanced Mathematical Performance
The added mathematical libraries provide:
- **OpenMP**: Parallel processing capabilities
- **OpenBLAS**: Highly optimized BLAS routines
- **LAPACK**: Advanced linear algebra operations
- **Eigen3**: High-performance C++ linear algebra
- **ATLAS**: Automatically tuned mathematical libraries

### Dependency Analysis
All dependencies are actively used:
- No redundant packages identified
- Mathematical libraries complement each other
- Each provides specific optimizations for TensorFlow

### Testing
- All dependencies verified through automated tests
- OS compatibility checking implemented
- Package installation validation included
- CPU feature detection confirmed

### Compatibility
- **OS**: Ubuntu 20.04+ (primary), Debian 12+ (supported)
- **Python**: 3.9-3.12 (tested with 3.12)
- **CPU**: AVX2 and FMA support required
- **Memory**: 8GB minimum, 16GB recommended
- **Storage**: 50GB free space minimum