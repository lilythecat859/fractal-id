// lib/main.dart
import 'package:flutter/material.dart';
import 'package:fractal_wallet/id_to_image.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FractalID',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff121212),
        colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  Uint8List? _pngBytes;

  Future<void> _generate() async {
    final addr = _ctrl.text.trim();
    if (addr.isEmpty) return;
    setState(() => _busy = true);
    final png = await IdToImage.addressToPng(addr);
    setState(() {
      _pngBytes = png;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FractalID')),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'Paste wallet address',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _generate(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Generate'),
                onPressed: _busy ? null : _generate,
              ),
              const SizedBox(height: 24),
              if (_busy) const CircularProgressIndicator(),
              if (_pngBytes != null) ...[
                Image.memory(_pngBytes!, width: 280, height: 280),
                const SizedBox(height: 8),
                Text(
                  _ctrl.text.trim().replaceRange(
                      6, _ctrl.text.trim().length - 6, '…'),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy address',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _ctrl.text.trim()));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Address copied')));
                        }),
                    IconButton(
                        icon: const Icon(Icons.save_alt),
                        tooltip: 'Save image',
                        onPressed: () => IdToImage.savePng(_pngBytes!)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
