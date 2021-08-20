OS := $(shell uname -s)
SOURCES := $(shell find src -name "*.cr")
ifeq (${OS},Darwin)
	SOURCES += $(shell pwd)/src/platform/mac.c
endif

shard.lock: shard.yml
	shards install

bin/triangle: shard.lock ${SOURCES} examples/triangle.cr
	@mkdir -p bin
ifeq (${OS},Darwin)
	crystal build examples/triangle.cr -o bin/triangle --link-flags $(shell pwd)/src/platform/mac.c
else
	crystal build examples/triangle.cr -o bin/triangle
endif

bin/triangle.app: bin/triangle
ifeq (${OS},Darwin)
	@echo "Fixing up libwgpu_native dylib path…"
	@install_name_tool -change /Users/runner/work/wgpu-native/wgpu-native/target/debug/deps/libwgpu_native.dylib @executable_path/../../Frameworks/libwgpu_native.dylib bin/triangle
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