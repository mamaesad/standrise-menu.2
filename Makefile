TARGET := iphone:clang:latest:13.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = StandRiseMenu

StandRiseMenu_FILES = \
    Bootstrap.mm \
    Cheat/Runtime.mm \
    Cheat/Game.mm \
    Cheat/Features.mm \
    UI/ESPDrawView.mm \
    UI/MenuWindow.mm \
    Touch/TouchHook.mm

StandRiseMenu_CFLAGS = -fobjc-arc -std=c++17 -I. -Wno-deprecated-declarations -Wno-unused-function
StandRiseMenu_LDFLAGS = -undefined dynamic_lookup
StandRiseMenu_FRAMEWORKS = UIKit Foundation QuartzCore
StandRiseMenu_INSTALL_PATH = /usr/lib

include $(THEOS_MAKE_PATH)/library.mk
