OS := $(shell uname -s)
SOURCES := $(shell find src -name "*.cr")
CFLAGS :=

ifeq (${MODE},Release)
	SOURCES += clean
	CFLAGS += --release
else
	CFLAGS += --debug
ifeq (${MODE},Debug)
	CFLAGS += --verbose
endif
endif

ifeq (${OS},Darwin)
	SOURCES += $(shell pwd)/src/platform/mac.c
	CFLAGS += --link-flags $(shell pwd)/src/platform/mac.c
endif
ifeq (${OS},Linux)
	ARCH := $(shell uname -m)
	LIB_ARCH := $(shell gcc -dumpmachine)
ifeq (${MODE},Release)
	CFLAGS += --link-flags '-Xlinker -rpath=\"/usr/lib/${LIB_ARCH}\"'
endif
endif

clean:
	rm -r bin
.PHONY: clean

shard.lock: shard.yml
	shards install

############
# EXAMPLES #
############

# Triangle
bin/triangle: shard.lock ${SOURCES} examples/triangle.cr
	@mkdir -p bin
	crystal build examples/triangle.cr -o bin/triangle ${CFLAGS}
ifeq (${OS},Darwin)
	@echo "Fixing up libwgpu_native dylib path…"
	@install_name_tool -change /Users/runner/work/wgpu-native/wgpu-native/target/debug/deps/libwgpu_native.dylib @executable_path/../lib/wgpu/bin/libs/libwgpu_native.dylib bin/triangle
endif

bin/triangle.app: bin/triangle
ifeq (${OS},Darwin)
	@echo "Fixing up libwgpu_native dylib path…"
	@install_name_tool -change @executable_path/../lib/wgpu/bin/libs/libwgpu_native.dylib @executable_path/../../Frameworks/libwgpu_native.dylib bin/triangle
	@otool -L bin/triangle | grep wgpu
	@rm -rf "bin/triangle.app"
	@lib/wgpu/scripts/appify.sh bin/triangle
	@mkdir -p "triangle.app/Frameworks"
	@cp lib/wgpu/bin/libs/libwgpu_native.dylib "triangle.app/Frameworks"
	@cp examples/Info.plist "triangle.app/Contents"
	@mv -f "triangle.app" bin
else
	@echo "macOS app construction is unavailable on this platform"
	@false
endif

# Cube with keyboard input
bin/cube: shard.lock ${SOURCES} examples/cube.cr
	@mkdir -p bin
	crystal build examples/cube.cr -o bin/cube ${CFLAGS}
ifeq (${OS},Darwin)
	@echo "Fixing up libwgpu_native dylib path…"
	@install_name_tool -change /Users/runner/work/wgpu-native/wgpu-native/target/debug/deps/libwgpu_native.dylib @executable_path/../lib/wgpu/bin/libs/libwgpu_native.dylib bin/cube
endif
