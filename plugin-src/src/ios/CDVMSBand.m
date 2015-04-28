

#import "CDVMSBand.h"

@interface MSBandPlugin () {}
@property (nonatomic, weak) MSBClient *client;
@property (nonatomic, retain) NSString* connectCallbackId;
@end

@implementation MSBandPlugin

-(void)connect:(CDVInvokedUrlCommand*)command
{
	[[MSBClientManager sharedManager] setDelegate:self];
	NSArray *attachedClients = [[MSBClientManager sharedManager] attachedClients];
    
    self.connectCallbackId = [NSString stringWithString:command.callbackId ];

	_client = [attachedClients firstObject];
	if (_client)
	{
        // connect to it
		[[MSBClientManager sharedManager] connectClient:_client];
	}
    else {
        
        // TODO: no bands detected
    }
}

// Note: The delegate methods of MSBClientManagerDelegate protocol are called in the main thread.
-(void)clientManager:(MSBClientManager *)cm clientDidConnect:(MSBClient *)client
{
    // handle connected event.
    self.client = client;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.connectCallbackId];
    
}

-(void)clientManager:(MSBClientManager *)cm clientDidDisconnect:(MSBClient *)client
{
	// handle disconnected event.
    // TODO: pass back something to say that this is a disconnect, and different fromt the error below.
    self.client = nil;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [pluginResult setKeepCallbackAsBool:NO];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.connectCallbackId];
}

-(void)clientManager:(MSBClientManager *)cm client:(MSBClient *)client didFailToConnectWithError:(NSError *)error
{
    // handle connect error event.
    // TODO: pass back resultCode based on this type of error
    self.client = nil;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [pluginResult setKeepCallbackAsBool:NO];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.connectCallbackId];
}


- (void)queryBandInfo:(CDVInvokedUrlCommand*)command
{
    __weak MSBClient* weakClient = self.client;
    __block NSString* callbackId = [NSString stringWithString:command.callbackId ];
    
	// gets firmwareVersion and hardwareVersion
 	[weakClient firmwareVersionWithCompletionHandler:^(NSString *version, NSError *error){
        // create a dictionary to hold our results
        NSMutableDictionary* versionInfo = [NSMutableDictionary dictionaryWithCapacity:7];
        
        versionInfo[@"maxMessageTitle"] = @(MSBNotificationMessageTitleLengthMax);
        versionInfo[@"maxMessageBody"] = @(MSBNotificationMessageBodyLengthMax);
        versionInfo[@"maxDialogTitle"] = @(MSBNotificationDialogTitleLengthMax);
        versionInfo[@"maxDialogBody"] = @(MSBNotificationDialogBodyLengthMax);
        versionInfo[@"maxTileName"] = @(MSBTileNameMaxLength);
        
        
        if (error) {
            // handle error
            dispatch_async(dispatch_get_main_queue(), ^{
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            });
        }
        else {
            // handle success
            // set the frameworkVersion, and go get the hardware version
            [versionInfo setObject:[NSString stringWithString:version] forKey:@"frameworkVersion"];
            [weakClient hardwareVersionWithCompletionHandler:^(NSString *hwVersion, NSError *error){
                if (error) {
                    // handle error
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
                    });
                }
                else {
                    // handle success
                    // got the hardware version
                    [versionInfo setObject:[NSString stringWithString:hwVersion] forKey:@"hardwareVersion"];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:versionInfo];
                        
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
                    });
                }
            }];
        }
    }];
}

- (void)watchSensor:(CDVInvokedUrlCommand*)command
{
// calories is a thing too
//
//            [self.client.sensorManager startCaloriesUpdatesToQueue:<#(NSOperationQueue *)#> errorRef:<#(NSError *__autoreleasing *)#> withHandler:<#^(MSBSensorCaloriesData *caloriesData, NSError *error)handler#>
    
    __block NSString* callbackId = [NSString stringWithString:command.callbackId ];
    __block NSString* event = [NSString stringWithString:(NSString*)command.arguments[0]];
    
    if([event compare:@"bandcontact"] == 0) {

        [self.client.sensorManager startBandContactUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorBandContactData *contactData, NSError *error) {
            NSMutableDictionary* reading = [NSMutableDictionary dictionaryWithCapacity:4];
            
            [reading setValue:[NSNumber numberWithInt:contactData.wornState] forKey:@"wornState"];
            [reading setValue:[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)] forKey:@"timestamp"];
            
            NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:4];
            [payload setValue:event forKey:@"event"];
            [payload setValue:reading forKey:@"reading"];

            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:payload];
            [result setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }];
        
    }
    else if([event compare:@"accelerometer"] == 0) {
        [self.client.sensorManager startAccelerometerUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorAccelData *accelerometerData, NSError *error) {
            
            NSMutableDictionary* reading = [NSMutableDictionary dictionaryWithCapacity:4];
            
            [reading setValue:[NSNumber numberWithDouble:accelerometerData.x] forKey:@"x"];
            [reading setValue:[NSNumber numberWithDouble:accelerometerData.y] forKey:@"y"];
            [reading setValue:[NSNumber numberWithDouble:accelerometerData.z] forKey:@"z"];
            [reading setValue:[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)] forKey:@"timestamp"];
            
            NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:4];
            [payload setValue:event forKey:@"event"];
            [payload setValue:reading forKey:@"reading"];
            
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:payload];
            [result setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }];
    }
    else if([event compare:@"gyroscope"] == 0) {
        [self.client.sensorManager startGyroscopeUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorGyroData *accelGyroData, NSError *error) {
            
            NSMutableDictionary* reading = [NSMutableDictionary dictionaryWithCapacity:4];
            
            [reading setValue:[NSNumber numberWithDouble:accelGyroData.x] forKey:@"x"];
            [reading setValue:[NSNumber numberWithDouble:accelGyroData.y] forKey:@"y"];
            [reading setValue:[NSNumber numberWithDouble:accelGyroData.z] forKey:@"z"];
            [reading setValue:[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)] forKey:@"timestamp"];
            
            NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:2];
            [payload setValue:event forKey:@"event"];
            [payload setValue:reading forKey:@"reading"];
            
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:payload];
            [result setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }]; 
    }
    else if([event compare:@"distance"] == 0) {
        [self.client.sensorManager startDistanceUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorDistanceData *distanceData, NSError *error) {
            
            NSMutableDictionary* reading = [NSMutableDictionary dictionaryWithCapacity:5];
            
            [reading setValue:[NSNumber numberWithDouble:distanceData.totalDistance] forKey:@"totalDistance"];
            [reading setValue:[NSNumber numberWithDouble:distanceData.speed] forKey:@"speed"];
            [reading setValue:[NSNumber numberWithDouble:distanceData.pace] forKey:@"pace"];
            [reading setValue:[NSNumber numberWithInt:distanceData.pedometerMode ]forKey:@"pedometerMode"];
            [reading setValue:[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)] forKey:@"timestamp"];
            
            NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:2];
            [payload setValue:event forKey:@"event"];
            [payload setValue:reading forKey:@"reading"];
            
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:payload];
            [result setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];

        }];
    }
    else if([event compare:@"heartrate"] == 0) {
        [self.client.sensorManager startHearRateUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorHeartRateData *heartRateData, NSError *error) {
            //heartRate,quality
            NSMutableDictionary* reading = [NSMutableDictionary dictionaryWithCapacity:3];
            
            [reading setValue:[NSNumber numberWithDouble:heartRateData.heartRate] forKey:@"heartRate"];
            [reading setValue:[NSNumber numberWithInt:heartRateData.quality] forKey:@"quality"];
            [reading setValue:[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)] forKey:@"timestamp"];
            
            NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:2];
            [payload setValue:event forKey:@"event"];
            [payload setValue:reading forKey:@"reading"];
            
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:payload];
            [result setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }];
    }
    else if([event compare:@"pedometer"] == 0) {
        [self.client.sensorManager startPedometerUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorPedometerData *pedometerData, NSError *error) {
            //totalSteps, stepRate, movementRate, totalMovements, movementMode
            NSMutableDictionary* reading = [NSMutableDictionary dictionaryWithCapacity:6];
            
            [reading setValue:[NSNumber numberWithInt:pedometerData.totalSteps] forKey:@"totalSteps"];
            [reading setValue:[NSNumber numberWithDouble:pedometerData.stepRate] forKey:@"stepRate"];
            [reading setValue:[NSNumber numberWithDouble:pedometerData.movementRate] forKey:@"movementRate"];
            [reading setValue:[NSNumber numberWithInt:pedometerData.totalMovements ]forKey:@"totalMovements"];
            [reading setValue:[NSNumber numberWithInt:pedometerData.movementMode ]forKey:@"movementMode"];
            
            [reading setValue:[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)] forKey:@"timestamp"];
            
            NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:2];
            [payload setValue:event forKey:@"event"];
            [payload setValue:reading forKey:@"reading"];
            
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:payload];
            [result setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }];
    }
    else if([event compare:@"skintemperature"] == 0) {
        [self.client.sensorManager startSkinTempUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorSkinTempData *skinTempData, NSError *error) {
            //temperature
            NSMutableDictionary* reading = [NSMutableDictionary dictionaryWithCapacity:2];
            
            [reading setValue:[NSNumber numberWithDouble:skinTempData.temperature] forKey:@"temperature"];
            [reading setValue:[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)] forKey:@"timestamp"];
            
            NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:2];
            [payload setValue:event forKey:@"event"];
            [payload setValue:reading forKey:@"reading"];
            
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:payload];
            [result setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }];
    }
    else if([event compare:@"uvlevel"] == 0) {
        [self.client.sensorManager startUVUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorUVData *UVData, NSError *error) {
            //uvIndexLevel [ MSBUVLevelNone, MSBUVLevelLow, MSBUVLevelMedium, MSBUVLevelHigh, MSBUVLevelVeryHigh ]
            NSMutableDictionary* reading = [NSMutableDictionary dictionaryWithCapacity:2];
            
            [reading setValue:[NSNumber numberWithDouble:UVData.uvIndexLevel] forKey:@"uvIndexLevel"];
            [reading setValue:[NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)] forKey:@"timestamp"];
            
            NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:2];
            [payload setValue:event forKey:@"event"];
            [payload setValue:reading forKey:@"reading"];
            
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:payload];
            [result setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
            
        }];
    }
}

- (void)unwatchSensor:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = [NSString stringWithString:command.callbackId ];
    NSString* event = [NSString stringWithString:(NSString*)command.arguments[0]];
    
    if([event compare:@"bandcontact"] == 0) {
        [self.client.sensorManager stopBandContactUpdatesErrorRef:nil];
    }
    else if([event compare:@"accelerometer"] == 0) {
        [self.client.sensorManager stopAccelerometerUpdatesErrorRef:nil];
    }
    else if([event compare:@"gyroscope"] == 0) {
        [self.client.sensorManager stopGyroscopeUpdatesErrorRef:nil];
    }
    else if([event compare:@"distance"] == 0) {
        [self.client.sensorManager stopDistanceUpdatesErrorRef:nil];
    }
    else if([event compare:@"heartrate"] == 0) {
        [self.client.sensorManager stopHeartRateUpdatesErrorRef:nil];
    }
    else if([event compare:@"pedometer"] == 0) {
        [self.client.sensorManager stopPedometerUpdatesErrorRef:nil];
    }
    else if([event compare:@"skintemperature"] == 0) {
        [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
    }
    else if([event compare:@"uvlevel"] == 0) {
        [self.client.sensorManager stopUVUpdatesErrorRef:nil];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];

}

- (void)vibrate:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = [NSString stringWithString:command.callbackId ];
    // send a vibration request of type alert alarm to the Band
    /*
     MSBVibrationTypeNotificationOneTone = 0x07,
     MSBVibrationTypeNotificationTwoTone = 0x10,
     MSBVibrationTypeNotificationAlarm   = 0x11,
     MSBVibrationTypeNotificationTimer   = 0x12,
     MSBVibrationTypeOneToneHigh         = 0x1B,
     MSBVibrationTypeTwoToneHigh         = 0x1D,
     MSBVibrationTypeThreeToneHigh       = 0x1C,
     MSBVibrationTypeRampUp              = 0x05,
     MSBVibrationTypeRampDown            = 0x04
     */
    [self.client.notificationManager vibrateWithType:MSBVibrationTypeNotificationOneTone
                                     completionHandler:^(NSError *error) {
        if (error){
            // TODO: handle error
        }
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)addTile:(CDVInvokedUrlCommand*)command
{
    /*
 * @param tileId        A unique identifier for the tile.
 * @param tileName      The display name of the tile.
 * @param tileIcon      The main tile icon.
 * @param smallIcon     The icon to be used in notifications and badging.
    */
    __block NSString* callbackId = [NSString stringWithString:command.callbackId ];
    
    NSUUID *tileId = [[NSUUID alloc] initWithUUIDString:(NSString*)command.arguments[0]];
    NSString* tileName = [NSString stringWithString:(NSString*)command.arguments[1]];
    NSString* iconFilePath = [NSString stringWithString:(NSString*)command.arguments[2]];
    NSString* smIconFilePath = [NSString stringWithString:(NSString*)command.arguments[3]];
    
    
    NSError* err;
    UIImage* tileImg = [UIImage imageNamed:iconFilePath];
    MSBIcon *tileIcon = [MSBIcon iconWithUIImage:tileImg error:&err];
    if(err) {
        NSLog(@"Error: %@", err.localizedDescription);
        // todo: return error to js
        return;
    }
    
    UIImage* smallImg = [UIImage imageNamed:smIconFilePath];
    MSBIcon *smallIcon = [MSBIcon iconWithUIImage:smallImg error:&err];
    if(err) {
        NSLog(@"Error: %@", err.localizedDescription);
        // todo: return error to js
        return;
    }
    
    MSBTile *tile = [MSBTile tileWithId:tileId name:tileName tileIcon:tileIcon smallIcon:smallIcon error:&err];
    
    if(err) {
        NSLog(@"Error: %@", err.localizedDescription);
        // todo: return error to js
    }
    else {
        
        [self.client.tileManager addTile:tile completionHandler:^(NSError *error) {
            if (error)
            {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            }
            else
            {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            }
        }];
    }
}

- (void)removeTile:(CDVInvokedUrlCommand*)command
{
    __block NSString* callbackId = [NSString stringWithString:command.callbackId ];
    NSUUID *tileId = [[NSUUID alloc] initWithUUIDString:(NSString*)command.arguments[0]];
    
    [self.client.tileManager removeTileWithId:tileId completionHandler:^(NSError *error) {
        if(error) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
        else {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    }];
}

/*
- (void)tilesWithCompletionHandler:(void(^)(NSArray *tiles, NSError *error))completionHandler;
- (void)setPages:(NSArray *)pageData tileId:(NSUUID *)tileId completionHandler:(void (^)(NSError *error))completionHandler;
- (void)removePagesInTile:(NSUUID *)tileId completionHandler:(void (^)(NSError *error))completionHandler;
*/

-(void)sendMesageWithTileId:(CDVInvokedUrlCommand*)command
{
    __block NSString* callbackId = [NSString stringWithString:command.callbackId ];
    NSUUID *tileId = [[NSUUID alloc] initWithUUIDString:(NSString*)command.arguments[0]];
    
    NSString* title = [NSString stringWithString:(NSString*)command.arguments[1]];
    NSString* body = [NSString stringWithString:(NSString*)command.arguments[2]];
    
    [self.client.notificationManager sendMessageWithTileID:tileId title:title body:body timeStamp:[NSDate date] flags:MSBNotificationMessageFlagsNone completionHandler:^(NSError *error) {
        if (!error) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
        else
        {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    }];

}

- (void)getRemainingTileCapacity:(CDVInvokedUrlCommand*)command
{
    __block NSString* callbackId = [NSString stringWithString:command.callbackId ];
    
    [self.client.tileManager remainingTileCapacityWithCompletionHandler:^(NSUInteger remainingCapacity, NSError *error) {
        if(!error){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:(int)remainingCapacity];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
        else {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    }];
    
}


///////// Theming

-(void)getCurrentTheme:(CDVInvokedUrlCommand*)command
{
    
    __block NSString* callbackId = [NSString stringWithString:command.callbackId ];
    [self.client.personalizationManager
     themeWithCompletionHandler:^(MSBTheme *theme, NSError *error){
         if (!error){
             
             NSMutableDictionary* themeMap = [NSMutableDictionary dictionaryWithCapacity:6];
             
             [themeMap setValue:[self hexStringFromUIColor:[theme.highLightColor UIColor]] forKey:@"highLightColor"];
             
             [themeMap setValue:[self hexStringFromUIColor:[theme.highContrastColor UIColor]] forKey:@"highContrastColor"];
             
             [themeMap setValue:[self hexStringFromUIColor:[theme.lowLightColor UIColor]] forKey:@"lowLightColor"];
             
             [themeMap setValue:[self hexStringFromUIColor:[theme.secondaryTextColor UIColor]] forKey:@"secondaryTextColor"];
             
             [themeMap setValue:[self hexStringFromUIColor:[theme.mutedColor UIColor]]
                 forKey:@"mutedColor"];
             
             [themeMap setValue:[self hexStringFromUIColor:[theme.baseColor UIColor]]
                 forKey:@"baseColor"];
             
             CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:themeMap];

             
             [self.commandDelegate sendPluginResult:result callbackId:callbackId];
         }
         else {
             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
             [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
         }
     }];
    
}




-(void)setCurrentTheme:(CDVInvokedUrlCommand*)command
{
    __block NSString* callbackId = [NSString stringWithString:command.callbackId ];
    
    MSBColor *base = [self colorFromHexString:(NSString*)command.arguments[0]];
    MSBColor *highlight = [self colorFromHexString:(NSString*)command.arguments[1]];
    MSBColor *lowlight = [self colorFromHexString:(NSString*)command.arguments[2]];
    MSBColor *secondary = [self colorFromHexString:(NSString*)command.arguments[3]];
    MSBColor *highContrast = [self colorFromHexString:(NSString*)command.arguments[4]];
    MSBColor *muted = [self colorFromHexString:(NSString*)command.arguments[5]];
    
    
    MSBTheme *theme = [MSBTheme themeWithBaseColor:base
                                   highLightColor:highlight
                                     lowLightColor:lowlight
                                 secondaryTextColor:secondary
                                 highContrastColor:highContrast
                                        mutedColor:muted];

    
    
    [self.client.personalizationManager updateTheme:theme
                                  completionHandler:^(NSError *error)
    {
        if (!error){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
        else {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    }];
}

- (NSString *)hexStringFromUIColor:(UIColor *)color {
    const CGFloat *parts = CGColorGetComponents(color.CGColor);
    NSString* hexString =  [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(parts[0] * 255),
            lroundf(parts[1] * 255),
            lroundf(parts[2] * 255)];
    return hexString;
}


-(MSBColor*)colorFromHexString:(NSString*)hexString
{
    unsigned int rgbValue = 0;
    NSScanner* scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    
   return [MSBColor colorWithRed:((rgbValue & 0xFF0000) >> 16)
                           green:((rgbValue & 0xFF00) >> 8)
                           blue:(rgbValue & 0xFF) ];
}


@end
