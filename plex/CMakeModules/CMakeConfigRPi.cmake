# vim: setlocal syntax=cmake:

if(UNIX)
  set(CMAKE_REQUIRED_FLAGS "-D__LINUX_USER__")
endif()

set(LINK_PKG
  FFmpeg
  Freetype
  ZLIB
  JPEG
  SQLite3
  PCRE
  SDL
  SDL_image
  SDL_mixer
  X11
  Lzo2
  FriBiDi
  Fontconfig
  Samplerate
  YAJL
  microhttpd
  Crypto
  TinyXML
  GLEW
  Iconv
  Avahi
  LibDl
  LibRt
)



#        --disable-optical-drive 
#  --disable-debug \
#   \
# --with-platform=raspberry-pi --enable-optimizations \
#                    --enable-libcec --enable-player=omxplayer

foreach(l ${LINK_PKG})
  plex_find_package(${l} 1 1)
endforeach()

#find_package(OpenGLES2 REQUIRED)
#include_directories(${OpenGLES2_INCLUDE_DIRS})
#set(CONFIG_PLEX_LINK_LIBRARIES ${CONFIG_PLEX_LINK_LIBRARIES} ${OpenGLES2_LIBRARIES})
#  
find_package(Boost COMPONENTS thread system REQUIRED)
if(Boost_FOUND)
  include_directories(${Boost_INCLUDE_DIRS})
  list(APPEND CONFIG_PLEX_LINK_LIBRARIES ${Boost_LIBRARIES})
  set(HAVE_BOOST 1)
endif()

### install libs
set(INSTALL_LIB
  CURL
  PNG
  TIFF
  Vorbis
  LibMad
  Mpeg2
  Ass
  RTMP
  PLIST
  ShairPort
  CEC
)

foreach(l ${INSTALL_LIB})
  plex_find_package(${l} 1 0)
endforeach()

plex_find_package(Threads 1 0)
if(CMAKE_USE_PTHREADS_INIT)
  message(STATUS "Using pthreads: ${CMAKE_THREAD_LIBS_INIT}")
  list(APPEND CONFIG_PLEX_LINK_LIBRARIES ${CMAKE_THREAD_LIBS_INIT})
  set(HAVE_LIBPTHREAD 1)
endif()


plex_find_package(LibUSB 0 1)
plex_find_package(LibUDEV 0 1)

if(NOT LIBUSB_FOUND AND NOT LIBUDEV_FOUND)
  message(WARNING "No USB support")
endif()


plex_get_soname(CURL_SONAME ${CURL_LIBRARY})

list(APPEND CONFIG_INTERNAL_LIBS lib_dllsymbols)



#### default lircdevice
set(LIRC_DEVICE "/dev/lircd")

#### on linux we want to use a "easy" name
set(EXECUTABLE_NAME "plexhometheater")

set(ARCH "arm")
set(USE_OPENGLES 1)
set(USE_OMXLIB 1)
set(USE_OPENMAX 0)
set(USE_CRYSTALHD 0)
set(USE_PULSE 0)
set(DISABLE_PROJECTM 1)
set(USE_TEXTUREPACKER_NATIVE_ROOT 0)



set(BUILD_DVDCSS 0)
set(SKIP_CONFIG_DVDCSS 1)
set(DVDREAD_CFLAGS "-D_XBMC -UHAVE_DVDCSS_DVDCSS_H")

add_definitions(
    -DTARGET_POSIX 
    -DTARGET_LINUX 
    -D_LINUX 
    -D_ARMEL 
    -DTARGET_RASPBERRY_PI
    -DHAS_GLES=2
    -DHAVE_LIBGLESV2
    -DHAS_EGL
    -DHAVE_OMXLIB
    -DOMX_SKIP64BIT
    -DHAS_BUILTIN_SYNC_ADD_AND_FETCH
    -DHAS_BUILTIN_SYNC_SUB_AND_FETCH
    -DHAS_BUILTIN_SYNC_VAL_COMPARE_AND_SWAP
    -DHAS_OMXPLAYER

    -DPIC 
    -D_REENTRANT 
    -D_LARGEFILE64_SOURCE 
    -D_FILE_OFFSET_BITS=64 
    -DNDEBUG=1 
)

include_directories(
    /opt/vc/include/ 
    /opt/vc/include/EGL 
   # /opt/vc/include/GLES 
    /opt/vc/include/GLES2 
    /opt/vc/include/KHR 
    /opt/vc/include/VG 
    /opt/vc/include/WF 
    /opt/vc/include/vc/include  
)





plex_find_library(GLESv2 0  0 /opt/vc/lib 1)
plex_find_library(EGL 0 0  /opt/vc/lib 1)
plex_find_library(vcos 0 0  /opt/vc/lib 1)
plex_find_library(bcm_host 0 0  /opt/vc/lib 1)
plex_find_library(vchiq_arm 0 0  /opt/vc/lib 1)


set(CMAKE_C_FLAGS " -isystem/usr/include -isystem/opt/vc/include -isystem/opt/vc/include/interface/vcos/pthreads -isystem/opt/vc -isystem/opt/vc/include/interface/vmcs_host/linux/ -isystem/opt/vc/include/EGL -isystem/opt/vc/include/GLES -isystem/opt/vc/include/GLES2 -isystem/opt/vc/include/KHR -isystem/opt/vc/include/VG -L/lib -L/usr/lib -L/opt/vc/lib -Wl,-rpath-link,/lib -Wl,-rpath-link,/lib -Wl,-rpath-link,/usr/lib -Wl,-rpath-link,/opt/vc/ -fPIC -pipe -O3 -mcpu=arm1176jzf-s -mtune=arm1176jzf-s -mfloat-abi=hard -mfpu=vfp -mabi=aapcs-linux -Wno-psabi -Wa,-mno-warn-deprecated -Wno-deprecated-declarations ")

set(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS})

set(LIBPATH bin)
set(BINPATH bin)
set(RESOURCEPATH share/XBMC)

set(PLEX_LINK_WRAPPED "-Wl,--unresolved-symbols=ignore-all -Wl,-wrap,_IO_getc -Wl,-wrap,_IO_getc_unlocked -Wl,-wrap,_IO_putc -Wl,-wrap,__fgets_chk -Wl,-wrap,__fprintf_chk -Wl,-wrap,__fread_chk -Wl,-wrap,__fxstat64 -Wl,-wrap,__lxstat64 -Wl,-wrap,__printf_chk -Wl,-wrap,__read_chk -Wl,-wrap,__vfprintf_chk -Wl,-wrap,__xstat64 -Wl,-wrap,_stat -Wl,-wrap,calloc -Wl,-wrap,clearerr -Wl,-wrap,close -Wl,-wrap,closedir -Wl,-wrap,dlopen -Wl,-wrap,fclose -Wl,-wrap,fdopen -Wl,-wrap,feof -Wl,-wrap,ferror -Wl,-wrap,fflush -Wl,-wrap,fgetc -Wl,-wrap,fgetpos -Wl,-wrap,fgetpos64 -Wl,-wrap,fgets -Wl,-wrap,fileno -Wl,-wrap,flockfile -Wl,-wrap,fopen -Wl,-wrap,fopen64 -Wl,-wrap,fprintf -Wl,-wrap,fputc -Wl,-wrap,fputs -Wl,-wrap,fread -Wl,-wrap,free -Wl,-wrap,freopen -Wl,-wrap,fseek -Wl,-wrap,fseeko64 -Wl,-wrap,fsetpos -Wl,-wrap,fsetpos64 -Wl,-wrap,fstat -Wl,-wrap,ftell -Wl,-wrap,ftello64 -Wl,-wrap,ftrylockfile -Wl,-wrap,funlockfile -Wl,-wrap,fwrite -Wl,-wrap,getc -Wl,-wrap,getc_unlocked -Wl,-wrap,getmntent -Wl,-wrap,ioctl -Wl,-wrap,lseek -Wl,-wrap,lseek64 -Wl,-wrap,malloc -Wl,-wrap,open -Wl,-wrap,open64 -Wl,-wrap,opendir -Wl,-wrap,popen -Wl,-wrap,printf -Wl,-wrap,read -Wl,-wrap,readdir -Wl,-wrap,readdir64 -Wl,-wrap,realloc -Wl,-wrap,rewind -Wl,-wrap,rewinddir -Wl,-wrap,setvbuf -Wl,-wrap,ungetc -Wl,-wrap,vfprintf -Wl,-wrap,write")

set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} /opt/vc/lib )


set(PLEX_LINK_WHOLEARCHIVE -Wl,--whole-archive)
set(PLEX_LINK_NOWHOLEARCHIVE -Wl,--no-whole-archive)


message(STATUS "CONFIG_PLEX_LINK_LIBRARIES=${CONFIG_PLEX_LINK_LIBRARIES}")
