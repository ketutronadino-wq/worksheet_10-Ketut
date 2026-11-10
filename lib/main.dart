import 'package:flutter/material.dart';
import 'pages/device_demo_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KosFinderDeviceApp());
}

class KosFinderDeviceApp extends StatelessWidget {
  const KosFinderDeviceApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KosFinder - Device Demo',
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: const DeviceDemoPage(),
      );
}