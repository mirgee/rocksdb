# This provides a Makefile simulation of a Meta-internal folly integration.
# It is not validated for general use.
#
# USE_FOLLY links the build targets with libfolly.a. The latter could be
# built using 'make build_folly', or built externally and specified in
# the CXXFLAGS and EXTRA_LDFLAGS env variables. The build_detect_platform
# script tries to detect if an external folly dependency has been specified.
# If not, it exports FOLLY_PATH to the path of the installed Folly and
# dependency libraries.
#
# USE_FOLLY_LITE cherry picks source files from Folly to include in the
# RocksDB library. Its faster and has fewer dependencies on 3rd party
# libraries, but with limited functionality. For example, coroutine
# functionality is not available.
ifeq ($(USE_FOLLY),1)
ifeq ($(USE_FOLLY_LITE),1)
$(error Please specify only one of USE_FOLLY and USE_FOLLY_LITE)
endif
ifneq ($(strip $(FOLLY_PATH)),)
	BOOST_PATH      := $(firstword $(wildcard $(FOLLY_PATH)/../boost-*))
	DBL_CONV_PATH   := $(firstword $(wildcard $(FOLLY_PATH)/../double-conversion-*))
	GFLAGS_PATH     := $(firstword $(wildcard $(FOLLY_PATH)/../gflags-*))
	GLOG_PATH       := $(firstword $(wildcard $(FOLLY_PATH)/../glog-*))
	LIBEVENT_PATH   := $(firstword $(wildcard $(FOLLY_PATH)/../libevent-*))
	XZ_PATH         := $(firstword $(wildcard $(FOLLY_PATH)/../xz-*))
	LIBSODIUM_PATH  := $(firstword $(wildcard $(FOLLY_PATH)/../libsodium-*))
	FMT_PATH        := $(firstword $(wildcard $(FOLLY_PATH)/../fmt-*))
	LIBIBERTY_PATH  := $(firstword $(wildcard $(FOLLY_PATH)/../libiberty*))

	# For some reason, glog and fmt libraries are under either lib or lib64
	GLOG_LIB_PATH := $(firstword $(wildcard $(GLOG_PATH)/lib64) $(wildcard $(GLOG_PATH)/lib))
	FMT_LIB_PATH := $(firstword $(wildcard $(FMT_PATH)/lib64) $(wildcard $(FMT_PATH)/lib))
	LIBIBERTY_LIB_PATH := $(firstword $(wildcard $(LIBIBERTY_PATH)/lib64) $(wildcard $(LIBIBERTY_PATH)/lib))

	# AIX: pre-defined system headers are surrounded by an extern "C" block
	ifeq ($(PLATFORM), OS_AIX)
		PLATFORM_CCFLAGS += -I$(BOOST_PATH)/include -I$(DBL_CONV_PATH)/include -I$(GLOG_PATH)/include -I$(LIBEVENT_PATH)/include -I$(XZ_PATH)/include -I$(LIBSODIUM_PATH)/include -I$(FOLLY_PATH)/include -I$(FMT_PATH)/include
		PLATFORM_CXXFLAGS += -I$(BOOST_PATH)/include -I$(DBL_CONV_PATH)/include -I$(GLOG_PATH)/include -I$(LIBEVENT_PATH)/include -I$(XZ_PATH)/include -I$(LIBSODIUM_PATH)/include -I$(FOLLY_PATH)/include -I$(FMT_PATH)/include
	else
		PLATFORM_CCFLAGS += -isystem $(BOOST_PATH)/include -isystem $(DBL_CONV_PATH)/include -isystem $(GLOG_PATH)/include -isystem $(LIBEVENT_PATH)/include -isystem $(XZ_PATH)/include -isystem $(LIBSODIUM_PATH)/include -isystem $(FOLLY_PATH)/include -isystem $(FMT_PATH)/include
		PLATFORM_CXXFLAGS += -isystem $(BOOST_PATH)/include -isystem $(DBL_CONV_PATH)/include -isystem $(GLOG_PATH)/include -isystem $(LIBEVENT_PATH)/include -isystem $(XZ_PATH)/include -isystem $(LIBSODIUM_PATH)/include -isystem $(FOLLY_PATH)/include -isystem $(FMT_PATH)/include
	endif

	# Link all folly dependencies statically
	FOLLY_LDFLAGS = \
		$(FOLLY_PATH)/lib/libfolly.a \
		$(BOOST_PATH)/lib/libboost_context.a \
		$(BOOST_PATH)/lib/libboost_filesystem.a \
		$(BOOST_PATH)/lib/libboost_atomic.a \
		$(BOOST_PATH)/lib/libboost_program_options.a \
		$(BOOST_PATH)/lib/libboost_regex.a \
		$(BOOST_PATH)/lib/libboost_system.a \
		$(BOOST_PATH)/lib/libboost_thread.a \
		$(DBL_CONV_PATH)/lib/libdouble-conversion.a \
		$(FMT_LIB_PATH)/libfmt.a \
		$(LIBIBERTY_LIB_PATH)/libiberty.a \
		$(GLOG_LIB_PATH)/libglog.a \
		$(GFLAGS_PATH)/lib/libgflags.a \
		$(LIBEVENT_PATH)/lib/libevent.a \
		-ldl \
		-pthread

	PLATFORM_LDFLAGS += $(FOLLY_LDFLAGS)
	JAVA_LDFLAGS += $(FOLLY_LDFLAGS)
	JAVA_STATIC_LDFLAGS += $(FOLLY_LDFLAGS)
endif
	PLATFORM_CCFLAGS += -DUSE_FOLLY -DFOLLY_NO_CONFIG
	PLATFORM_CXXFLAGS += -DUSE_FOLLY -DFOLLY_NO_CONFIG
	# NOTE: Removed for arm64
	# PLATFORM_CCFLAGS += -DUSE_FOLLY
	# PLATFORM_CXXFLAGS += -DUSE_FOLLY
endif

ifeq ($(USE_FOLLY_LITE),1)
	# Path to the Folly source code and include files
	FOLLY_DIR = ./third-party/folly
ifneq ($(strip $(BOOST_SOURCE_PATH)),)
	BOOST_INCLUDE = $(shell (ls -d $(BOOST_SOURCE_PATH)/boost*/))
	# AIX: pre-defined system headers are surrounded by an extern "C" block
	ifeq ($(PLATFORM), OS_AIX)
		PLATFORM_CCFLAGS += -I$(BOOST_INCLUDE)
		PLATFORM_CXXFLAGS += -I$(BOOST_INCLUDE)
	else
		PLATFORM_CCFLAGS += -isystem $(BOOST_INCLUDE)
		PLATFORM_CXXFLAGS += -isystem $(BOOST_INCLUDE)
	endif
endif  # BOOST_SOURCE_PATH
	# AIX: pre-defined system headers are surrounded by an extern "C" block
	ifeq ($(PLATFORM), OS_AIX)
		PLATFORM_CCFLAGS += -I$(FOLLY_DIR)
		PLATFORM_CXXFLAGS += -I$(FOLLY_DIR)
	else
		PLATFORM_CCFLAGS += -isystem $(FOLLY_DIR)
		PLATFORM_CXXFLAGS += -isystem $(FOLLY_DIR)
	endif
	PLATFORM_CCFLAGS += -DUSE_FOLLY -DFOLLY_NO_CONFIG
	PLATFORM_CXXFLAGS += -DUSE_FOLLY -DFOLLY_NO_CONFIG
# TODO: fix linking with fbcode compiler config
	PLATFORM_LDFLAGS += -lglog
endif

FOLLY_COMMIT_HASH = abe68f7e917e8b7a0ee2fe066c972dc98fd35aa1

# For public CI runs, checkout folly in a way that can build with RocksDB.
# This is mostly intended as a test-only simulation of Meta-internal folly
# integration.
checkout_folly:
	if [ -e third-party/folly ]; then \
		cd third-party/folly && ${GIT_COMMAND} fetch origin; \
	else \
		cd third-party && ${GIT_COMMAND} clone https://github.com/facebook/folly.git; \
	fi
	@# Pin to a particular version for public CI, so that PR authors don't
	@# need to worry about folly breaking our integration. Update periodically
	cd third-party/folly && git reset --hard $(FOLLY_COMMIT_HASH)
	@# Apparently missing include
	perl -pi -e 's/(#include <atomic>)/$$1\n#include <cstring>/' third-party/folly/folly/lang/Exception.h
	@# const mismatch
	perl -pi -e 's/: environ/: (const char**)(environ)/' third-party/folly/folly/Subprocess.cpp
	@# Use gnu.org mirrors to improve download speed (ftp.gnu.org is often super slow)
	cd third-party/folly && perl -pi -e 's/ftp.gnu.org/ftpmirror.gnu.org/' `git grep -l ftp.gnu.org` README.md
	@# NOTE: boost and fmt source will be needed for any build including `USE_FOLLY_LITE` builds as those depend on those headers
	cd third-party/folly && GETDEPS_USE_WGET=1 $(PYTHON) build/fbcode_builder/getdeps.py fetch boost --scratch-path $${GETDEPS_SCRATCH_PATH:-/tmp} && GETDEPS_USE_WGET=1 $(PYTHON) build/fbcode_builder/getdeps.py fetch fmt --scratch-path $${GETDEPS_SCRATCH_PATH:-/tmp}

CXX_M_FLAGS = $(filter -m%, $(CXXFLAGS))

FOLLY_BUILD_FLAGS = --no-tests
# NOTE: To avoid ODR violations, we must build folly in debug mode iff
# building RocksDB in debug mode.
ifneq ($(DEBUG_LEVEL),0)
FOLLY_BUILD_FLAGS += --build-type Debug
endif

# Only propagate "target selection" flags to Folly (safe across platforms)
ifeq ($(ARMCRC_SOURCE),1)
  ARCH_CFLAGS   := $(filter -march=% -mcpu=% -mtune=%,$(CFLAGS))
  ARCH_CXXFLAGS := $(filter -march=% -mcpu=% -mtune=%,$(CXXFLAGS))
else
  ARCH_CFLAGS   :=
  ARCH_CXXFLAGS :=
endif

FOLLY_CFLAGS   := -fPIC $(ARCH_CFLAGS)
FOLLY_CXXFLAGS := -fPIC -DHAVE_CXX11_ATOMIC $(ARCH_CXXFLAGS)

build_folly:
	FOLLY_INST_PATH=`cd third-party/folly && $(PYTHON) build/fbcode_builder/getdeps.py show-inst-dir --scratch-path $${GETDEPS_SCRATCH_PATH:-/tmp}`; \
	if [ "$$FOLLY_INST_PATH" ]; then \
		rm -rf $${FOLLY_INST_PATH}/../../*; \
	else \
		echo "Please run checkout_folly first"; \
		false; \
	fi
	cd third-party/folly && \
	GETDEPS_USE_WGET=1 \
	CFLAGS="$(FOLLY_CFLAGS)" \
	CXXFLAGS="$(CXX_M_FLAGS) $(FOLLY_CXXFLAGS)" \
	$(PYTHON) build/fbcode_builder/getdeps.py build \
		--scratch-path $${GETDEPS_SCRATCH_PATH:-/tmp} \
		--allow-system-packages \
		--no-tests \
		--extra-cmake-defines "{\"BUILD_SHARED_LIBS\":\"OFF\",\"CMAKE_C_FLAGS\":\"$(FOLLY_CFLAGS)\",\"CMAKE_CXX_FLAGS\":\"$(CXX_M_FLAGS) $(FOLLY_CXXFLAGS)\",\"CMAKE_POSITION_INDEPENDENT_CODE\":\"ON\",\"OPENSSL_INCLUDE_DIR\":\"/opt/openssl11/include\",\"OPENSSL_CRYPTO_LIBRARY\":\"/opt/openssl11/lib/libcrypto.a\",\"OPENSSL_SSL_LIBRARY\":\"/opt/openssl11/lib/libssl.a\",\"OPENSSL_ROOT_DIR\":\"/opt/openssl11\",\"OPENSSL_USE_STATIC_LIBS\":\"TRUE\",\"FOLLY_USE_JEMALLOC\":\"OFF\",\"FOLLY_HAVE_JEMALLOC\":\"OFF\",\"JEMALLOC_FOUND\":\"OFF\",\"FOLLY_USE_SYMBOLIZER\":\"OFF\",\"FOLLY_HAVE_LIBUNWIND\":\"OFF\",\"FOLLY_HAVE_DWARF\":\"OFF\",\"FOLLY_HAVE_ELF\":\"OFF\",\"CMAKE_DISABLE_FIND_PACKAGE_LibUnwind\":\"ON\",\"WITH_UNWIND\":\"OFF\",\"WITH_SYMBOLIZE\":\"OFF\"}"
	@# In the folly build, glog and gflags are only built as dynamic libraries,
	@# not static. This patchelf command is needed to reliably have the glog
	@# library find its dependency gflags, because apparently the rpath of the
	@# final binary is not used in resolving that transitive dependency.
	FOLLY_INST_PATH=`cd third-party/folly && $(PYTHON) build/fbcode_builder/getdeps.py show-inst-dir  --scratch-path $${GETDEPS_SCRATCH_PATH:-/tmp}`; \
	cd "$$FOLLY_INST_PATH" && patchelf --add-rpath $$PWD/../gflags-*/lib ../glog-*/lib*/libglog*.so.*.*.*
