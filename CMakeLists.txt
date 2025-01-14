cmake_minimum_required(VERSION 3.10)
project(torrey_gpu)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Enable C++17 for host code
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Set a default build type if none was specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    SET(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    SET_PROPERTY(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

########################################
# CUDA Setup
########################################
find_package(CUDA 10 REQUIRED)
include(${CMAKE_MODULE_PATH}/CUDAComputesList.cmake)

list(APPEND CUDA_NVCC_FLAGS ${CUDA_GENERATE_CODE} "--std=c++17" "--expt-relaxed-constexpr" "--use_fast_math")
list(APPEND CUDA_NVCC_FLAGS_DEBUG "-g -G")
set(CUDA_VERBOSE_BUILD ON)

if(WIN32)
    # Set up include and lib paths
    set(CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER} CACHE FILEPATH "Host side compiler used by NVCC" FORCE)
endif(WIN32)
########################################

set(SRC 
    src/3rdparty/miniz.h
    src/3rdparty/miniz.c
    src/3rdparty/pugiconfig.hpp
    src/3rdparty/pugixml.hpp
    src/3rdparty/pugixml.cpp
    src/3rdparty/stb_image.h
    src/3rdparty/tinyexr.h
    src/3rdparty/tinyply.h
    src/compute_normals.h
    src/flexception.h
    src/render.h
    src/render.cu
    src/image.h
    src/matrix.h
    src/parse_obj.h
    src/parse_ply.h
    src/parse_scene.h
    src/parse_serialized.h
    src/print_scene.h
    src/torrey.h
    src/transform.h
    src/vector.h
    src/compute_normals.cpp
    src/image.cpp
    src/main.cpp
    src/parse_obj.cpp
    src/parse_ply.cpp
    src/parse_scene.cpp
    src/parse_serialized.cpp
    src/print_scene.cpp
    src/transform.cpp
    src/bbox.h
    src/bvh.h         
    src/bvh.cpp
    src/camera.h
    src/camera.cpp
    src/intersection.h
    src/light.h
    src/material.h
    src/ray.h
    src/scene.h
    src/scene.cpp
    src/shape.h
    src/texture.h
    src/materials/diffuse.inl
    src/materials/mirror.inl
    src/materials/plastic.inl
    src/materials/phong.inl
    src/materials/blinn_phong.inl
    src/materials/blinn_phong_microfacet.inl
    )

list(SORT SRC)
source_group(Sources FILES ${SRC})
cuda_add_executable(${CMAKE_PROJECT_NAME} ${SRC})

target_link_libraries(${CMAKE_PROJECT_NAME} ${CUDA_curand_LIBRARY} ${CUDA_CUDART_LIBRARY} ${CUDA_LIBRARIES})