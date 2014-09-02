ARCHS = armv7 arm64
TARGET = iphone::7.0
include theos/makefiles/common.mk

TWEAK_NAME = GeoEventSubstrate
GeoEventSubstrate_FILES = Tweak.xm
GeoEventSubstrate_FRAMEWORKS = UIKit
GeoEventSubstrate_LIBRARIES = activator objcipc
GeoEventSubstrate_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
