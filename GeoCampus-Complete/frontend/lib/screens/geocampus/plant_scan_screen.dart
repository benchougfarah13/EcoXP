import 'dart:convert';

import 'package:eco_collect/constants/kenums.dart';
import 'package:eco_collect/constants/ktheme.dart';
import 'package:eco_collect/models/geocampus_campus_zone.dart';
import 'package:eco_collect/screens/geocampus/plant_data.dart';
import 'package:eco_collect/services/geocampus_local_state.dart';
import 'package:eco_collect/services/geocampus_rewards.dart';
import 'package:eco_collect/utils/kloading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Campus plant hunt merged from Student Hunter — feeds the same XP / trophies loop.
class PlantScanScreen extends StatefulWidget {
  const PlantScanScreen({super.key, this.zoneId});

  /// When set, successful scans improve this zone on the campus health map.
  final String? zoneId;

  @override
  State<PlantScanScreen> createState() => _PlantScanScreenState();
}

class _PlantScanScreenState extends State<PlantScanScreen> {
  static const double _minConfidence = 0.60;
  static const int _xpReward = 28;
  static const int _trophyReward = 18;

  final List<Plant> _plants = plantList;
  int _currentPlantIndex = 0;
  String _statusMessage = 'Find the plant shown below';
  bool _uploadInProgress = false;
  String _pcIpAddress = '';

  Plant get _currentPlant => _plants[_currentPlantIndex];

  @override
  void initState() {
    super.initState();
    _loadPcIpAddress();
  }

  Future<void> _loadPcIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pcIpAddress = prefs.getString('geocampus_pc_ip_address') ??
          prefs.getString('pc_ip_address') ??
          '';
    });
  }

  Future<void> _savePcIpAddress(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geocampus_pc_ip_address', ip.trim());
    if (!mounted) return;
    setState(() => _pcIpAddress = ip.trim());
  }

  void _advancePlant() {
    if (_currentPlantIndex < _plants.length - 1) {
      setState(() {
        _currentPlantIndex += 1;
        _statusMessage = 'Nice! Next plant on campus';
      });
    } else {
      setState(() {
        _statusMessage = 'You catalogued every spotlight species!';
      });
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
    }
  }

  bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    if (value is num) return value != 0;
    return fallback;
  }

  double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  String _normalizePlantName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _zoneName() {
    if (widget.zoneId == null) return null;
    for (final z in GeocampusCampusZone.campusDefaults) {
      if (z.id == widget.zoneId) return z.name;
    }
    return null;
  }

  Future<void> _onSuccessfulTargetScan(double confidence) async {
    await GeocampusRewards.grantExplorationReward(
      context,
      xp: _xpReward,
      trophies: _trophyReward,
    );
    await GeocampusLocalState.markDailyScanDone();
    if (widget.zoneId != null) {
      await GeocampusLocalState.addZoneBoost(widget.zoneId!, 6);
    }
    if (!mounted) return;
    final zone = _zoneName();
    KLoadingToast.showNotification(
      msg: zone != null
          ? 'You improved $zone ✦ +$_xpReward XP'
          : 'Eco Guardian progress +$_xpReward XP',
      toastType: KenumToastType.success,
      durationInSeconds: 3,
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _advancePlant();
    });
  }

  Future<void> _sendBytesToRecognitionServer(List<int> imageBytes) async {
    if (_pcIpAddress.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set recognition server IP in settings (or use Demo).'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _uploadInProgress = true);
    try {
      final response = await http
          .post(
            Uri.parse('http://$_pcIpAddress:8888/upload'),
            headers: {
              'Content-Type': 'application/octet-stream',
              'X-File-Type': 'Plant',
            },
            body: imageBytes,
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final plantName = body['plant'] as String? ?? 'Unknown';
        final match = _parseBool(body['match'], fallback: false);
        final confidence = _parseDouble(body['confidence'], fallback: 0.0);
        final serverMessage = body['message']?.toString();

        final normalizedRecognized = _normalizePlantName(plantName);
        final normalizedTarget = _normalizePlantName(_currentPlant.name);
        final isCorrectPlant = match &&
            confidence >= _minConfidence &&
            normalizedRecognized == normalizedTarget;

        _updateStatus(isCorrectPlant
            ? 'This is ${_currentPlant.name} (${(confidence * 100).toStringAsFixed(0)}% confidence).'
            : match
                ? (confidence < _minConfidence
                    ? 'Low confidence (${(confidence * 100).toStringAsFixed(0)}%). Try a clearer photo of ${_currentPlant.name}.'
                    : 'Looks like $plantName — keep hunting ${_currentPlant.name}.')
                : (serverMessage != null && serverMessage.isNotEmpty
                    ? serverMessage
                    : 'No confident match. Frame ${_currentPlant.name} closer.'));

        if (isCorrectPlant) {
          await _onSuccessfulTargetScan(confidence);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot reach server: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadInProgress = false);
    }
  }

  Future<void> _captureAndUpload() async {
    final picker = ImagePicker();
    final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
    final XFile? shot = await picker.pickImage(source: source, imageQuality: 82);
    if (shot == null) return;
    final bytes = await shot.readAsBytes();
    await _sendBytesToRecognitionServer(bytes);
  }

  Future<void> _demoSuccessfulScan() async {
    _updateStatus(
        'Demo: ${_currentPlant.name} verified — great for pitch & Chrome builds.');
    await _onSuccessfulTargetScan(0.95);
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: _pcIpAddress);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KTheme.globalScaffoldFG,
        title: const Text('Recognition server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PC / LAN IP for your Python plant service (port 8888).'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '192.168.1.42',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              await _savePcIpAddress(controller.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zoneLabel = _zoneName();

    return Scaffold(
      backgroundColor: KTheme.globalScaffoldBG,
      appBar: AppBar(
        title: const Text('GeoCampus · Plant scan'),
        backgroundColor: KTheme.globalAppBarBG,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (zoneLabel != null)
            Text(
              'Zone: $zoneLabel',
              style: const TextStyle(
                color: KTheme.superLightBg,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Target species',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          Text(
            _currentPlant.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_currentPlant.type} · ${_currentPlant.characteristics}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _uploadInProgress ? null : _captureAndUpload,
                  icon: _uploadInProgress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(kIsWeb ? Icons.photo_library : Icons.camera_alt),
                  label: Text(kIsWeb ? 'Pick photo' : 'Scan with camera'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _showSettingsDialog,
                icon: const Icon(Icons.settings),
                color: Colors.white,
              ),
            ],
          ),
          if (kIsWeb || _pcIpAddress.isEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _uploadInProgress ? null : _demoSuccessfulScan,
              icon: const Icon(Icons.bolt),
              label: const Text('Demo scan (no server)'),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tip: same flow as Student Hunter — point the model at the spotlight plant, earn XP, and lift your zone on the campus map.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
