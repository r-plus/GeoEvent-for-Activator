ARCHS = armv7 arm64
TARGET = iphone::7.0

include theos/makefiles/common.mk

APPLICATION_NAME = GeoEvent
GeoEvent_FRAMEWORKS = CoreLocation MapKit UIKit CoreGraphics
GeoEvent_FILES = files/AddNewEventViewController.m \
				 files/LocationSettingViewController.m \
				 files/AppDelegate.m \
				 files/GeoFencingItemViewController.m \
				 files/ViewController.m \
				 files/main.m
GeoEvent_CFLAGS = -fobjc-arc
GeoEvent_LIBRARIES = objcipc activator

include $(THEOS_MAKE_PATH)/application.mk

SUBPROJECTS = geoeventsubstrate

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
