#import <React/RCTBridgeModule.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BleAdvertiseModule : NSObject <RCTBridgeModule, CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSDictionary *advertisingData;
@property (nonatomic, copy) RCTPromiseResolveBlock startResolve;
@property (nonatomic, copy) RCTPromiseRejectBlock startReject;
@end

@implementation BleAdvertiseModule

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(startAdvertising:(NSString *)uuidString
                  major:(nonnull NSNumber *)major
                  minor:(nonnull NSNumber *)minor
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  self.startResolve = resolve;
  self.startReject = reject;
  
  // Create a CBPeripheralManager to handle BLE advertising
  self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];

  // Convert the UUID string to a CBUUID
  CBUUID *serviceUUID = [CBUUID UUIDWithString:uuidString];

  // For a generic BLE advertisement, we advertise a service UUID.
  // If you want to do iBeacon-style advertising, note that Apple has restrictions and
  // you must format the advertisement data accordingly. This is a simple example.
  
  self.advertisingData = @{
    CBAdvertisementDataServiceUUIDsKey: @[serviceUUID]
  };
}

RCT_EXPORT_METHOD(stopAdvertising:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  if (self.peripheralManager) {
    [self.peripheralManager stopAdvertising];
    self.peripheralManager = nil; // Reset peripheralManager
    resolve(@"Advertising stopped");
  } else {
    reject(@"NOT_ADVERTISING", @"No advertising was running", nil);
  }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
  if (peripheral.state != CBManagerStatePoweredOn) {
    if (self.startReject) {
      self.startReject(@"PERIPHERAL_OFF", @"Bluetooth is off or not available", nil);
      self.startReject = nil;
      self.startResolve = nil;
    }
    return;
  }
  
  // Once Bluetooth is powered on, start advertising
  if (peripheral.state == CBManagerStatePoweredOn && self.advertisingData) {
    [self.peripheralManager startAdvertising:self.advertisingData];
    if (self.startResolve) {
      self.startResolve(@"Advertising started");
      self.startResolve = nil;
      self.startReject = nil;
    }
  }
}

@end
