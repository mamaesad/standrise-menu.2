// Bootstrap.mm — dylib entry point.
#import <UIKit/UIKit.h>
#include "Cheat/Runtime.h"
#include "Cheat/Game.h"
#include "Cheat/Features.h"
#include "UI/ESPDrawView.h"
#include "UI/MenuWindow.h"
#include "Touch/TouchHook.h"

static void SRStartUI(void) {
    [SREspView install];
    [SRMenuWindow install];
    sr_touchhook_install();
}

__attribute__((constructor)) static void SRBootstrap(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        sr::runtime_init();
        sr::game_init();
        sr::features_init();
        sr::load_config();
        SRStartUI();

        // The game may still be booting: retry until the IL2CPP runtime exposes
        // PlayerManager, then re-resolve feature anchors.
        static NSInteger attempts = 0;
        NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer* t) {
            attempts++;
            if (sr::game_ready()) {
                sr::features_init();
                [t invalidate];
                return;
            }
            sr::runtime_init();
            sr::game_init();
            if (attempts > 30) [t invalidate];
        }];
        (void)timer;
    });
}
