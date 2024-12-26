package com.sample

import android.bluetooth.*
import android.bluetooth.le.*
import android.util.Log
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import android.os.ParcelUuid

class BLEModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bleScanner: BluetoothLeScanner? = null
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null

    init {
        val bluetoothManager =
            reactContext.getSystemService(ReactApplicationContext.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter
    }

    override fun getName(): String = "BLEModule"

    //region Scanning

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            super.onScanResult(callbackType, result)
            val device = result.device
            val name = device?.name ?: "Unknown"
            val rssi = result.rssi

            val logMsg = "[Android] Discovered: $name (RSSI: $rssi)"
            Log.d(TAG, logMsg)
            sendLogToJS(logMsg)
        }

        override fun onScanFailed(errorCode: Int) {
            super.onScanFailed(errorCode)
            val logMsg = "[Android] Scan failed with error $errorCode"
            Log.d(TAG, logMsg)
            sendLogToJS(logMsg)
        }
    }

    @ReactMethod
fun startScan() {
    if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
        val logMsg = "[Android] Bluetooth is disabled or not available."
        Log.d(TAG, logMsg)
        sendLogToJS(logMsg)
        return
    }

    bleScanner = bluetoothAdapter?.bluetoothLeScanner
    bleScanner?.let {
        val logMsg = "[Android] BLE: Started scanning for advertising devices..."
        Log.d(TAG, logMsg)
        sendLogToJS(logMsg)

        // Service UUID to filter for advertising devices
        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid.fromString("0000180D-0000-1000-8000-00805f9b34fb"))
            .build()

        val filters = listOf(filter)
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY) // Low latency for active scanning
            .build()

        it.startScan(filters, settings, scanCallback)
    }
}

    @ReactMethod
    fun stopScan() {
        if (bleScanner != null && bluetoothAdapter?.isEnabled == true) {
            bleScanner?.stopScan(scanCallback)

            val logMsg = "[Android] BLE: Stopped scanning."
            Log.d(TAG, logMsg)
            sendLogToJS(logMsg)
        }
    }

    //endregion

    //region Advertising

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            super.onStartSuccess(settingsInEffect)
            val logMsg = "[Android] BLE: Advertising started successfully."
            Log.d(TAG, logMsg)
            sendLogToJS(logMsg)
        }

        override fun onStartFailure(errorCode: Int) {
            super.onStartFailure(errorCode)
            val logMsg = "[Android] BLE: Advertising failed with error $errorCode"
            Log.d(TAG, logMsg)
            sendLogToJS(logMsg)
        }
    }

    @ReactMethod
    fun startAdvertising() {
        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            val logMsg = "[Android] Bluetooth is disabled or not available."
            Log.d(TAG, logMsg)
            sendLogToJS(logMsg)
            return
        }

        bluetoothLeAdvertiser = bluetoothAdapter?.bluetoothLeAdvertiser
        if (bluetoothLeAdvertiser == null) {
            val logMsg = "[Android] BLE: Advertiser not supported on this device."
            Log.d(TAG, logMsg)
            sendLogToJS(logMsg)
            return
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true) // Include device name in advertisement
            .addServiceUuid(ParcelUuid.fromString("0000180D-0000-1000-8000-00805f9b34fb")) // Same UUID used in scan
            .setIncludeTxPowerLevel(true) // Include TX power level
            .build()

        val scanResponse = AdvertiseData.Builder()
            .setIncludeTxPowerLevel(true)
            .build()

        val logMsg = "[Android] BLE: Starting advertising with Service UUID: 0000180D-0000-1000-8000-00805f9b34fb"
        Log.d(TAG, logMsg)
        sendLogToJS(logMsg)

        bluetoothLeAdvertiser?.startAdvertising(settings, data, scanResponse, advertiseCallback)
    }


    @ReactMethod
    fun stopAdvertising() {
        bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
        val logMsg = "[Android] BLE: Stopped advertising."
        Log.d(TAG, logMsg)
        sendLogToJS(logMsg)
    }

    //endregion

    //region Helpers for sending logs to JS

    private fun sendLogToJS(message: String) {
        // We'll emit an event named "bleLog" to JS
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("bleLog", message)
    }

    companion object {
        private const val TAG = "BLEModule"
    }
}
