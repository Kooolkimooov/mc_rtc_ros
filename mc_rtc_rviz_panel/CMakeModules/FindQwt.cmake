# Adapted from
# https://stackoverflow.com/questions/58844585/use-qwt-installed-via-brew-in-cmake

file(GLOB QWT_CUSTOM_PATHS /usr/local/qwt-*)
set(QWT_PATHS ${QWT_CUSTOM_PATHS} /usr/local/ /usr /usr/local/share/
              /usr/share/ "${CMAKE_INSTALL_PREFIX}")

set(QWT_HINTS /usr/local/opt/qwt/lib)

if(USE_QT6)
  set(QWT_NAMES qwt-qt6 qwt)
  set(QWT_SUFFIXES include qwt-qt6 qwt6-qt6 qwt)
else()
  set(QWT_NAMES qwt-qt5 qwt qwt-qt4)
  set(QWT_SUFFIXES include qwt-qt5 qwt-qt4 qwt)
endif()
list(APPEND QWT_SUFFIXES include/qwt)

set(ARCH_SUFFIX "lib")
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
  set(ARCH_SUFFIX "")
endif()

find_library(
  Qwt_LIBRARY
  NAMES ${QWT_NAMES}
  PATHS ${QWT_PATHS}
  HINTS ${QWT_HINTS}
  PATH_SUFFIXES ${ARCH_SUFFIX}
  DOC "Variable storing the location of Qwt library")

if(Qwt_LIBRARY)
  get_filename_component(QWT_LIB_DIR ${Qwt_LIBRARY} DIRECTORY)
  get_filename_component(QWT_PREFIX ${QWT_LIB_DIR} DIRECTORY)
  find_path(
    Qwt_INCLUDE_DIR
    NAMES qwt.h
    PATHS ${QWT_PREFIX}
    PATH_SUFFIXES ${QWT_SUFFIXES}
    NO_DEFAULT_PATH)
endif()

find_path(
  Qwt_INCLUDE_DIR
  NAMES qwt.h
  PATHS ${QWT_PATHS}
  HINTS ${QWT_HINTS}
  PATH_SUFFIXES ${QWT_SUFFIXES} Headers
  DOC "Variable storing the location of Qwt header")

set(Qwt_VERSION ${Qwt_FIND_VERSION})
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  Qwt
  FOUND_VAR Qwt_FOUND
  REQUIRED_VARS Qwt_LIBRARY Qwt_INCLUDE_DIR
  VERSION_VAR Qwt_VERSION)

if(Qwt_FOUND)
  set(Qwt_LIBRARIES ${Qwt_LIBRARY})
  set(Qwt_INCLUDE_DIRS ${Qwt_INCLUDE_DIR})
endif()
if(Qwt_FOUND AND NOT TARGET Qwt::Qwt)
  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    get_filename_component(FRAMEWORK_LOC ${Qwt_LIBRARY} DIRECTORY)
    add_library(Qwt::Qwt INTERFACE IMPORTED)
    set_target_properties(
      Qwt::Qwt PROPERTIES INTERFACE_COMPILE_OPTIONS ""
                          INTERFACE_INCLUDE_DIRECTORIES "${Qwt_INCLUDE_DIR}")

    target_link_libraries(Qwt::Qwt
                          INTERFACE "-F${FRAMEWORK_LOC} -framework qwt")
  else()
    add_library(Qwt::Qwt UNKNOWN IMPORTED)
    set_target_properties(
      Qwt::Qwt
      PROPERTIES IMPORTED_LOCATION "${Qwt_LIBRARIES}"
                 INTERFACE_COMPILE_OPTIONS ""
                 INTERFACE_INCLUDE_DIRECTORIES "${Qwt_INCLUDE_DIR}")
  endif()
endif()
