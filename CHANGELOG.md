# Changelog

## [Updated] - 2025-06-01

### Updated Dependencies
- **TensorFlow**: 2.18.0 → 2.19.0 (latest stable release)
- **Bazelisk**: 6.5.0 → 1.26.0 (latest version with improved features)
- **NumPy**: 2.1.2 → 2.2.6 (latest compatible version)
- **Six**: 1.15.0 → 1.17.0 (latest version)

### New Features
- **Ubuntu Version Check**: Added automatic OS version detection and compatibility checking
- **Enhanced Dependencies**: Added essential mathematical and optimization libraries:
  - `libomp-dev` (OpenMP support for parallel processing)
  - `liblapack-dev` (Linear Algebra PACKage)
  - `libeigen3-dev` (C++ template library for linear algebra)
  - `libblas-dev` (Basic Linear Algebra Subprograms)
  - `libatlas-base-dev` (Automatically Tuned Linear Algebra Software)

### Improvements
- Fixed Bazelisk download URL to use correct version format (v1.26.0)
- Updated README.md with current version information and new dependencies
- Enhanced test script (`test_environment.py`) to verify all system packages and OS compatibility
- Verified compatibility with TensorFlow 2.19.0 and NumPy 2.2.6
- Maintained `cpuinfo` dependency (required for determining CPU core count for parallel compilation)
- Added support for Ubuntu 20.04+ with automatic version validation

### Technical Details
- All dependencies tested and verified working
- Bazelisk automatically manages Bazel version (currently downloads Bazel 8.2.1)
- Python 3.12 support confirmed
- AVX2 and FMA CPU feature detection working correctly
- Virtual environment creation and package installation verified

### Files Modified
- `tensorflow_builder.sh`: Updated version numbers and fixed download URL
- `README.md`: Updated documentation with new versions and improved descriptions
- Added `test_environment.py`: New test script for environment verification
- Added `CHANGELOG.md`: This changelog file

### Compatibility
- Ubuntu 20.04 LTS or higher (24.04 LTS recommended)
- Debian support with user confirmation
- Python 3.9-3.12 (tested with 3.12)
- CPUs with AVX2 and FMA support
- Enhanced system dependencies for improved mathematical performance