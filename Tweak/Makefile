DEBUG = 0
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
ARCHS = armv7 armv7s arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = musicsync
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = Foundation CoreFoundation UIKit MediaPlayer
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = StoreServices
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
