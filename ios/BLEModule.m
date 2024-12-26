#import "BLEModule.h"
#import <React/RCTLog.h>

@interface BLEModule()

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

@end

@implementation BLEModule

#pragma mark - Module Setup

// Make this class available in JavaScript as "BLEModule"
RCT_EXPORT_MODULE();

// We want to send events/logs from Native -> JS. Return the list of event names we might emit.
- (NSArray<NSString *> *)supportedEvents {
  return @[@"bleLog"];
}

// Make sure BLE callbacks run on main thread
- (dispatch_queue_t)methodQueue {
  return dispatch_get_main_queue();
}

#pragma mark - Public React Methods (Scan)

RCT_EXPORT_METHOD(startScan) {
  if (!self.centralManager) {
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
  }
  
  if (self.centralManager.state == CBManagerStatePoweredOn) {
    // Example Service UUID to filter advertising devices
    NSArray *serviceUUIDs = @[[CBUUID UUIDWithString:@"180D"]]; // Example UUID (Heart Rate Service)

    NSDictionary *scanOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO};

    [self.centralManager scanForPeripheralsWithServices:serviceUUIDs options:scanOptions];
    [self logToJS:@"[iOS] BLE: Started scanning for advertising devices with Service UUID: 180D"];
  } else {
    NSString *msg = [NSString stringWithFormat:@"[iOS] BLE: Central not ready. State: %ld", (long)self.centralManager.state];
    [self logToJS:msg];
  }
}


RCT_EXPORT_METHOD(stopScan) {
  if (self.centralManager && self.centralManager.state == CBManagerStatePoweredOn) {
    [self.centralManager stopScan];
    [self logToJS:@"[iOS] BLE: Stopped scanning."];
  }
}

#pragma mark - Public React Methods (Advertise)

RCT_EXPORT_METHOD(startAdvertising) {
  if (!self.peripheralManager) {
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
  }
  
  if (self.peripheralManager.state == CBManagerStatePoweredOn) {
    // Example advertisement: a local name + a common service UUID (e.g. Heart Rate 180D)
    NSDictionary *advertisingData = @{
      CBAdvertisementDataLocalNameKey: @"MyRNPeripheral",
      CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:@"180D"]]
    };
    [self.peripheralManager startAdvertising:advertisingData];
    [self logToJS:@"[iOS] BLE: Started advertising as a peripheral."];
  } else {
    NSString *msg = [NSString stringWithFormat:@"[iOS] BLE: Peripheral Manager not ready. State: %ld", (long)self.peripheralManager.state];
    [self logToJS:msg];
  }
}

RCT_EXPORT_METHOD(stopAdvertising) {
  if (self.peripheralManager && self.peripheralManager.state == CBManagerStatePoweredOn) {
    [self.peripheralManager stopAdvertising];
    [self logToJS:@"[iOS] BLE: Stopped advertising."];
  }
}

#pragma mark - CBCentralManagerDelegate (Scanning)

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  switch (central.state) {
    case CBManagerStatePoweredOn:
      [self logToJS:@"[iOS] BLE Central: Powered ON"];
      break;
    case CBManagerStatePoweredOff:
      [self logToJS:@"[iOS] BLE Central: Powered OFF"];
      break;
    case CBManagerStateUnauthorized:
      [self logToJS:@"[iOS] BLE Central: Unauthorized"];
      break;
    case CBManagerStateUnsupported:
      [self logToJS:@"[iOS] BLE Central: Unsupported"];
      break;
    case CBManagerStateResetting:
      [self logToJS:@"[iOS] BLE Central: Resetting"];
      break;
    case CBManagerStateUnknown:
      [self logToJS:@"[iOS] BLE Central: Unknown"];
      break;
    default:
      break;
  }
}

- (void)centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary<NSString *, id> *)advertisementData
                   RSSI:(NSNumber *)RSSI
{
  NSString *name = peripheral.name ?: @"Unknown";
  NSString *logMsg = [NSString stringWithFormat:@"[iOS] Discovered: %@ (RSSI: %@)", name, RSSI];
  [self logToJS:logMsg];
}

#pragma mark - CBPeripheralManagerDelegate (Advertising)

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
  switch (peripheral.state) {
    case CBManagerStatePoweredOn:
      [self logToJS:@"[iOS] BLE Peripheral: Powered ON"];
      break;
    case CBManagerStatePoweredOff:
      [self logToJS:@"[iOS] BLE Peripheral: Powered OFF"];
      break;
    case CBManagerStateUnauthorized:
      [self logToJS:@"[iOS] BLE Peripheral: Unauthorized"];
      break;
    case CBManagerStateUnsupported:
      [self logToJS:@"[iOS] BLE Peripheral: Unsupported"];
      break;
    case CBManagerStateResetting:
      [self logToJS:@"[iOS] BLE Peripheral: Resetting"];
      break;
    case CBManagerStateUnknown:
      [self logToJS:@"[iOS] BLE Peripheral: Unknown"];
      break;
    default:
      break;
  }
}

#pragma mark - Private Helpers

- (void)logToJS:(NSString *)message {
  // Send an event named "bleLog" to JS
  [self sendEventWithName:@"bleLog" body:@{@"message": message}];
}

@end
