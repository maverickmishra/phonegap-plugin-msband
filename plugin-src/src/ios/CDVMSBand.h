
#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>
#import <Cordova/CDVPlugin.h>

@interface MSBandPlugin : CDVPlugin<MSBClientManagerDelegate>
{

}

- (void)queryBandInfo:(CDVInvokedUrlCommand*)command;

- (void)watchSensor:(CDVInvokedUrlCommand*)command;

- (void)unwatchSensor:(CDVInvokedUrlCommand*)command;

- (void)vibrate:(CDVInvokedUrlCommand*)command;



@end
