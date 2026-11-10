import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/draft_repository.dart';
import '../services/device_location_service.dart';
import 'sensor_demo_page.dart';

class DeviceDemoPage extends StatefulWidget {
  const DeviceDemoPage({super.key});
  @override
  State<DeviceDemoPage> createState() => _DeviceDemoPageState();
}

class _DeviceDemoPageState extends State<DeviceDemoPage> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  final _drafts = DraftRepository();
  final _location = DeviceLocationService();

  String? _photoPath;
  double? _latitude;
  double? _longitude;
  LocationFailureType? _locationError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restoreLocalDraft();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restoreLocalDraft() async {
    try {
      final draft = await _drafts.load();
      if (!mounted) return;
      setState(() {
        _nameController.text = draft['name'] as String? ?? '';
        _photoPath = draft['photoPath'] as String?;
        final lat = draft['latitude'];
        final lng = draft['longitude'];
        _latitude = lat is num ? lat.toDouble() : null;
        _longitude = lng is num ? lng.toDouble() : null;
      });
    } catch (error) {
      _notice('Draft lokal belum dapat dibaca: $error');
    }
  }

  Future<void> _saveDraft() async {
    await _drafts.save({
      'name': _nameController.text.trim(),
      'photoPath': _photoPath,
      'latitude': _latitude,
      'longitude': _longitude,
    });
    _notice('Draft berhasil disimpan di perangkat.');
  }

  Future<void> _choosePhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      setState(() => _busy = true);
      final permanentPath = await _drafts.savePermanentPhoto(picked);
      if (!mounted) return;
      setState(() => _photoPath = permanentPath);
      _notice('Foto berhasil disimpan.');
    } catch (error) {
      _notice('Gagal memproses foto: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _getLocation() async {
    setState(() => _busy = true);
    try {
      final pos = await _location.getPosition();
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationError = null;
      });
      _notice('Koordinat berhasil diambil.');
    } on LocationFailure catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.type);
      _notice(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoExists = _photoPath != null && File(_photoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('KosFinder - Device Demo'),
        actions: [
          IconButton(
            tooltip: 'Demo sensor',
            icon: const Icon(Icons.sensors),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SensorDemoPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Mode: Lokal/Offline', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama kos (contoh: Kos Melati)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _choosePhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _choosePhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeri'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (photoExists)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(_photoPath!), height: 200, fit: BoxFit.cover),
            )
          else
            const Text('Belum ada foto. Pilih foto JPG/PNG maksimal 5 MB.'),
          const Divider(height: 28),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : _getLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Ambil Koordinat GPS'),
          ),
          const SizedBox(height: 6),
          Text(
            _latitude == null || _longitude == null
                ? 'Koordinat: belum diisi (opsional)'
                : 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    try {
                      await _saveDraft();
                    } catch (error) {
                      _notice('Gagal menyimpan draft: $error');
                    }
                  },
            icon: const Icon(Icons.save),
            label: const Text('Simpan Draft Lokal'),
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}