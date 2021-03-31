DEBUG = 0
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
ARCHS = armv7 armv7s arm64 arm64e

include $(THEOS)/makefiles/common.mk

TOOL_NAME = musicsync
$(TOOL_NAME)_FILES = main.mm
$(TOOL_NAME)_FRAMEWORKS = Foundation CoreFoundation
ADDITIONAL_OBJCFLAGS = -fobjc-arc

SUBPROJECTS = Tweak

include $(THEOS)/makefiles/tool.mk
include $(THEOS)/makefiles/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"