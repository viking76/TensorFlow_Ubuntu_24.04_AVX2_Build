#!/usr/bin/env python3
"""
Test script to verify the TensorFlow build environment is properly set up.
"""

import sys
import subprocess
import os

def test_python_version():
    """Test Python version compatibility."""
    print(f"Python version: {sys.version}")
    major, minor = sys.version_info[:2]
    if major == 3 and minor >= 11:
        print("✓ Python version is compatible")
        return True
    else:
        print("✗ Python version is not compatible (need 3.11+)")
        return False

def test_numpy():
    """Test NumPy installation and version."""
    try:
        import numpy as np
        print(f"NumPy version: {np.__version__}")
        # Test basic functionality
        arr = np.array([1, 2, 3])
        result = np.sum(arr)
        if result == 6:
            print("✓ NumPy is working correctly")
            return True
        else:
            print("✗ NumPy basic test failed")
            return False
    except ImportError:
        print("✗ NumPy is not installed")
        return False

def test_six():
    """Test Six installation and version."""
    try:
        import six
        print(f"Six version: {six.__version__}")
        # Test basic functionality
        if six.PY3:
            print("✓ Six is working correctly")
            return True
        else:
            print("✗ Six basic test failed")
            return False
    except ImportError:
        print("✗ Six is not installed")
        return False

def test_bazel():
    """Test Bazel/Bazelisk installation."""
    try:
        result = subprocess.run(['bazel', 'version'], 
                              capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            print("✓ Bazel/Bazelisk is installed and working")
            # Extract Bazelisk version from output
            for line in result.stderr.split('\n'):
                if 'Bazelisk version:' in line:
                    print(f"  {line.strip()}")
            return True
        else:
            print("✗ Bazel/Bazelisk test failed")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("✗ Bazel/Bazelisk is not installed or not accessible")
        return False

def test_cpu_features():
    """Test CPU features for AVX2 and FMA support."""
    try:
        with open('/proc/cpuinfo', 'r') as f:
            cpuinfo = f.read()
        
        has_avx2 = 'avx2' in cpuinfo
        has_fma = 'fma' in cpuinfo
        
        print(f"CPU AVX2 support: {'✓' if has_avx2 else '✗'}")
        print(f"CPU FMA support: {'✓' if has_fma else '✗'}")
        
        # Also check CPU core count for parallel compilation
        import os
        cpu_count = os.cpu_count()
        print(f"CPU cores available: {cpu_count}")
        
        return has_avx2 and has_fma
    except Exception as e:
        print(f"✗ Could not check CPU features: {e}")
        return False

def test_system_packages():
    """Test essential system packages installation."""
    packages = [
        "cpuinfo", "libomp-dev", "libopenblas-dev", "liblapack-dev", 
        "libeigen3-dev", "libblas-dev", "libatlas-base-dev"
    ]
    
    all_installed = True
    for package in packages:
        try:
            result = subprocess.run(['dpkg', '-s', package], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✓ {package} is installed")
            else:
                print(f"✗ {package} is not installed")
                all_installed = False
        except Exception as e:
            print(f"✗ Could not check {package}: {e}")
            all_installed = False
    
    return all_installed

def test_os_version():
    """Test operating system version compatibility."""
    try:
        with open('/etc/os-release', 'r') as f:
            os_info = {}
            for line in f:
                if '=' in line:
                    key, value = line.strip().split('=', 1)
                    os_info[key] = value.strip('"')
        
        os_id = os_info.get('ID', 'unknown')
        version_id = os_info.get('VERSION_ID', 'unknown')
        pretty_name = os_info.get('PRETTY_NAME', 'unknown')
        
        print(f"Operating System: {pretty_name}")
        
        if os_id == 'ubuntu':
            ubuntu_version = float(version_id)
            if ubuntu_version >= 20.04:
                print(f"✓ Ubuntu {version_id} is supported")
                return True
            else:
                print(f"⚠ Ubuntu {version_id} may not be fully supported (recommended: 20.04+)")
                return False
        elif os_id == 'debian':
            print("⚠ Debian detected - script optimized for Ubuntu but may work")
            return True
        else:
            print(f"✗ Unsupported OS: {pretty_name}")
            return False
            
    except Exception as e:
        print(f"✗ Could not check OS version: {e}")
        return False

def main():
    """Run all tests."""
    print("TensorFlow Build Environment Test")
    print("=" * 40)
    
    tests = [
        ("OS Version", test_os_version),
        ("Python Version", test_python_version),
        ("NumPy", test_numpy),
        ("Six", test_six),
        ("Bazel/Bazelisk", test_bazel),
        ("System Packages", test_system_packages),
        ("CPU Features", test_cpu_features),
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\nTesting {test_name}...")
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"✗ {test_name} test failed with exception: {e}")
            results.append((test_name, False))
    
    print("\n" + "=" * 40)
    print("Test Summary:")
    all_passed = True
    for test_name, passed in results:
        status = "PASS" if passed else "FAIL"
        print(f"  {test_name}: {status}")
        if not passed:
            all_passed = False
    
    print(f"\nOverall: {'ALL TESTS PASSED' if all_passed else 'SOME TESTS FAILED'}")
    return 0 if all_passed else 1

if __name__ == "__main__":
    sys.exit(main())