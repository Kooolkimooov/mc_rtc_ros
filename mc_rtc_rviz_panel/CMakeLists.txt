#
# Copyright 2016-2026 CNRS-UM LIRMM, CNRS-AIST JRL
#

cmake_minimum_required(VERSION 3.22)

set(PROJECT_NAME mc_rtc_rviz_panel)
set(PROJECT_DESCRIPTION "mc_rtc RVIz panel for prototyping controllers")
set(PROJECT_URL "")
set(CMAKE_CXX_STANDARD 17)

set(BUILD_PARALLEL_JOBS 5)

project(
  ${PROJECT_NAME}
  LANGUAGES CXX
  VERSION 1.6.1)

# Ensure RPATH is set for installed binaries
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

if(NOT DEFINED ENV{ROS_VERSION})
  message(FATAL_ERROR "Expected to find ROS_VERSION in the environment")
endif()
set(ROS_VERSION $ENV{ROS_VERSION})

find_package(mc_rtc REQUIRED)
if(NOT TARGET mc_rtc::mc_rtc_ros)
  message(FATAL_ERROR "mc_rtc ROS plugin is required to build this project")
endif()

if(NOT DEFINED ENV{ROS_DISTRO})
  set(ROS_DISTRO "none")
else()
  set(ROS_DISTRO "$ENV{ROS_DISTRO}")
endif()

if(NOT DEFINED ENV{MC_RTC_RVIZ_PANEL_FORCE_QT5})
  set(FORCE_QT5 0)
else()
  set(FORCE_QT5 $ENV{MC_RTC_RVIZ_PANEL_FORCE_QT5})
endif()

macro(add_ros2_dependency PKG TARGET)
  find_package(${PKG} REQUIRED)
  target_link_libraries(ROSDependencies INTERFACE ${PKG}::${TARGET})
endmacro()

if(ROS_VERSION EQUAL 1)
  find_package(catkin REQUIRED COMPONENTS roscpp tf rviz roslib)

  catkin_package(CATKIN_DEPENDS roscpp tf rviz roslib)

  include_directories(SYSTEM ${catkin_INCLUDE_DIRS})
  link_directories(${catkin_LIBRARY_DIRS})

  install(FILES rviz_plugin.xml DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})
elseif(ROS_VERSION EQUAL 2)
  cmake_minimum_required(VERSION 3.22)
  find_package(ament_cmake REQUIRED)

  add_library(ROSDependencies INTERFACE IMPORTED)
  add_ros2_dependency(rclcpp rclcpp)
  add_ros2_dependency(tf2_ros tf2_ros)
  add_ros2_dependency(visualization_msgs
                      visualization_msgs__rosidl_typesupport_cpp)
  add_ros2_dependency(interactive_markers interactive_markers)
  add_ros2_dependency(pluginlib pluginlib)
  add_ros2_dependency(rviz_common rviz_common)

  pluginlib_export_plugin_description_file(rviz_common plugin/rviz_plugin.xml)
else()
  message(FATAL_ERROR "ROS_VERSION ${ROS_VERSION} is not supported yet")
endif()

# Determine target Qt version
if(FORCE_QT5)
  set(DESIRED_QT_VERSION 5)
elseif(TARGET Qt6::Widgets OR TARGET Qt6::Core)
  set(DESIRED_QT_VERSION 6)
elseif(TARGET Qt5::Widgets OR TARGET Qt5::Core)
  set(DESIRED_QT_VERSION 5)
else()
  if("${ROS_DISTRO}" STREQUAL "lyrical" OR "${ROS_DISTRO}" STREQUAL "rolling")
    set(DESIRED_QT_VERSION 6)
  else()
    set(DESIRED_QT_VERSION 5)
  endif()
endif()

# Check for Qt version conflict specifically in RViz
if(TARGET rviz_common::rviz_common)
  get_target_property(LIBS rviz_common::rviz_common INTERFACE_LINK_LIBRARIES)
  get_target_property(QT_VER rviz_common::rviz_common
                      INTERFACE_QT_MAJOR_VERSION)
  set(RVIZ_QT_VER 0)
  if(QT_VER)
    set(RVIZ_QT_VER ${QT_VER})
  elseif("${LIBS}" MATCHES "Qt6")
    set(RVIZ_QT_VER 6)
  elseif("${LIBS}" MATCHES "Qt5")
    set(RVIZ_QT_VER 5)
  elseif("${LIBS}" MATCHES "Qt4")
    set(RVIZ_QT_VER 4)
  endif()

  if(RVIZ_QT_VER GREATER 0 AND NOT RVIZ_QT_VER EQUAL DESIRED_QT_VERSION)
    message(
      FATAL_ERROR
        "Qt version mismatch: rviz_common requires Qt${RVIZ_QT_VER} but project is targeting Qt${DESIRED_QT_VERSION} (FORCE_QT5=${FORCE_QT5})"
    )
  endif()
endif()

set(USE_QT6 0)
if(DESIRED_QT_VERSION EQUAL 6)
  set(USE_QT6 1)
endif()

message(
  STATUS
    "mc_rtc_rviz_panel: USE_QT6=${USE_QT6} (target Qt${DESIRED_QT_VERSION})")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_SOURCE_DIR}/CMakeModules)
find_package(Qwt)

add_subdirectory(src)

if(ROS_VERSION EQUAL 2)
  ament_package()
endif()
