APP_NAME := Awake
BUILD_DIR := build
SOURCES := $(wildcard Awake/*.swift)
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
ARCH := $(shell uname -m)

.PHONY: all clean run

all: $(APP_BUNDLE)

$(BUILD_DIR)/$(APP_NAME): $(SOURCES)
	@mkdir -p $(BUILD_DIR)
	swiftc \
		-target $(ARCH)-apple-macos13.0 \
		-sdk $$(xcrun --show-sdk-path) \
		-parse-as-library \
		-o $@ \
		$(SOURCES)

$(APP_BUNDLE): $(BUILD_DIR)/$(APP_NAME) Awake/Info.plist
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	@cp Awake/Info.plist $(APP_BUNDLE)/Contents/
	@codesign -s - -f $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

run: $(APP_BUNDLE)
	@open $(APP_BUNDLE)

clean:
	rm -rf $(BUILD_DIR)
