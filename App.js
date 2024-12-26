import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  Button,
  NativeModules,
  NativeEventEmitter,
  StyleSheet,
  ScrollView,
  Platform,
} from 'react-native';

const { BLEModule } = NativeModules;
const bleEventEmitter = new NativeEventEmitter(BLEModule);

export default function App() {
  const [logs, setLogs] = useState([]);
  const [scanning, setScanning] = useState(false);
  const [advertising, setAdvertising] = useState(false);

  useEffect(() => {
    // Listen for bleLog events from native
    const subscription = bleEventEmitter.addListener('bleLog', (message) => {
      console.log('[BLE LOG]', message);
      setLogs((prevLogs) => [...prevLogs, message]);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  const startScan = () => {
    BLEModule.startScan();
    setScanning(true);
  };

  const stopScan = () => {
    BLEModule.stopScan();
    setScanning(false);
  };

  const startAdvertise = () => {
    BLEModule.startAdvertising();
    setAdvertising(true);
  };

  const stopAdvertise = () => {
    BLEModule.stopAdvertising();
    setAdvertising(false);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>BLE Example (Central & Peripheral)</Text>
      <Text>Platform: {Platform.OS}</Text>

      <View style={styles.row}>
        {scanning ? (
          <Button title="Stop Scan" onPress={stopScan} />
        ) : (
          <Button title="Start Scan" onPress={startScan} />
        )}
        {advertising ? (
          <Button title="Stop Advertise" onPress={stopAdvertise} />
        ) : (
          <Button title="Start Advertise" onPress={startAdvertise} />
        )}
      </View>

      <ScrollView style={styles.logs}>
        {logs.map((log, i) => (
          <Text key={i} style={styles.logText}>
            {JSON.stringify(log)}
          </Text>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, paddingTop: 40 },
  title: { fontSize: 20, fontWeight: '600', marginBottom: 10 },
  row: { flexDirection: 'row', justifyContent: 'space-between', marginVertical: 20 },
  logs: { flex: 1, marginTop: 10, backgroundColor: '#f4f4f4', padding: 8 },
  logText: { fontSize: 14, marginVertical: 2 },
});
