APP_NAME := Awake
BUILD_DIR := build
SOURCES := $(wildcard Awake/*.swift)
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
ARCH := $(shell uname -m)

.PHONY: all clean run setup

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

setup:
	@echo "Setting up passwordless pmset for $(USER)..."
	@echo '$(USER) ALL=(ALL) NOPASSWD: /usr/bin/pmset disablesleep 0, /usr/bin/pmset disablesleep 1' | sudo tee /etc/sudoers.d/zzz-awake > /dev/null
	@sudo chmod 0440 /etc/sudoers.d/zzz-awake
	@sudo visudo -cf /etc/sudoers.d/zzz-awake
	@echo "Done. Awake can now toggle sleep without password prompts."

clean:
	rm -rf $(BUILD_DIR)
