.PHONY: all clean menuconfig rebuild

BUILD_DIR := build
CMAKE_CACHE := $(BUILD_DIR)/CMakeCache.txt

all: config
	@cd $(BUILD_DIR) && $(MAKE) && cd ..

config: $(CMAKE_CACHE)

clean:
	rm -fr $(BUILD_DIR)

rebuild: clean all

$(CMAKE_CACHE):
	@cmake -S . -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)

menuconfig: $(BUILD_DIR)
	cmake-gui $(BUILD_DIR)