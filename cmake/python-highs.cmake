if (NOT PYTHON_BUILD_SETUP)
  return()
endif()

# set(CMAKE_VERBOSE_MAKEFILE ON)

include(sources-python)

set(sources_python ${highs_sources_python} 
                   ${cupdlp_sources_python} 
                   ${ipx_sources_python} 
                   ${basiclu_sources_python})

if (CUPDLP_GPU)
  list(APPEND sources_python ${cuda_sources_python})
endif()

set(headers_python ${highs_headers_python} 
                   ${cupdlp_headers_python} 
                   ${ipx_headers_python} 
                   ${basiclu_headers_python})

if (CUPDLP_GPU)
  list(APPEND headers_python ${cuda_headers_python})
endif()

# Find Python 3
find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)
find_package(pybind11 CONFIG)

python_add_library(_core MODULE highs/highs_bindings.cpp WITH_SOABI)

# Pybind11
# include(FetchContent)
# message(CHECK_START "Fetching pybind11")
# list(APPEND CMAKE_MESSAGE_INDENT "  ")
# set(PYBIND11_INSTALL ON)
# set(PYBIND11_TEST OFF)
# FetchContent_Declare(
#   pybind11
#   GIT_REPOSITORY "https://github.com/pybind/pybind11.git"
#   GIT_TAG "v2.11.1"
# )
# FetchContent_MakeAvailable(pybind11)
# list(POP_BACK CMAKE_MESSAGE_INDENT)
# message(CHECK_PASS "fetched")

# add module
# pybind11_add_module(highspy highspy/highs_bindings.cpp)

target_link_libraries(_core PRIVATE pybind11::headers)

# sources for python 
target_sources(_core PUBLIC ${sources_python} ${headers_python})

# include directories for python 
target_include_directories(_core PUBLIC ${include_dirs_python})

# This is passing in the version as a define just as an example
target_compile_definitions(_core PRIVATE VERSION_INFO=${PROJECT_VERSION})

# GPU support configuration
if(CUPDLP_GPU)
  message(STATUS "Building Python extension with GPU support")
  
  # Enable CUDA language
  enable_language(CUDA)
  
  # Find CUDA toolkit - use the same logic as main CMake
  if (CUPDLP_FIND_CUDA)
    # With FindCUDAConf.cmake
    # Need to have the CUDA_HOME environment variable set.
    include(FindCUDAConf)
  else() 
    # Without FindCUDAConf.cmake
    find_package(CUDAToolkit REQUIRED)
    set(CUDA_LIBRARY CUDA::cudart CUDA::cublas CUDA::cusparse)
  endif()
  
  # Add CUDA include directories
  target_include_directories(_core PRIVATE "$<BUILD_INTERFACE:${CMAKE_CUDA_PATH}/include>")
  
  # Set CUDA compilation properties
  set_target_properties(_core PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
  
  # Link CUDA libraries
  if (WIN32)
    target_link_libraries(_core PRIVATE ${CUDA_LIBRARY})
  else()
    target_link_libraries(_core PRIVATE ${CUDA_LIBRARY} m)
  endif()
  

  message(STATUS "CUDA libraries: ${CUDA_LIBRARY}")
endif()

if(MSVC)
  target_compile_options(_core PRIVATE "/bigobj")
else()
  # Increase template instantiation depth for complex pybind11 bindings
  target_compile_options(_core PRIVATE "-ftemplate-depth=1500")
endif()

# if(MSVC)
#   # Try to split large pdb files into objects. 
#   # https://github.com/tensorflow/tensorflow/issues/31610
#   add_compile_options("/Z7")
#   add_link_options("/DEBUG:FASTLINK")
#   if(STDCALL)
#     # /Gz - stdcall calling convention
#     add_definitions(/Gz)
#   endif()
# endif()

# The install directory is the output (wheel) directory
install(TARGETS _core DESTINATION highspy)
