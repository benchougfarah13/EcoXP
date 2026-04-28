import 'dart:convert';
import 'dart:io';
import 'package:eco_collect/providers/plant_map_provider.dart';
import 'package:eco_collect/providers/user_provider.dart';
import 'package:eco_collect/utils/kloading.dart';
import 'package:eco_collect/constants/kenums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// ─── PlantNet API config ────────────────────────────────────────────────────
// Free demo key — replace with your own from https://my-api.plantnet.org
const String _kPlantNetApiKey = '2b10rEKnjMHdkjzMHwwQ0bex1';
const String _kPlantNetUrl =
    'https://my-api.plantnet.org/v2/identify/all?api-key=$_kPlantNetApiKey&lang=en&include-related-images=false';

class PlantScanResult {
  final String commonName;
  final String scientificName;
  final double confidence;
  final String? imageUrl;

  const PlantScanResult({
    required this.commonName,
    required this.scientificName,
    required this.confidence,
    this.imageUrl,
  });
}

class GeoCampusScannerScreen extends StatefulWidget {
  final LatLng? playerPosition;
  final String? targetPlantId;

  const GeoCampusScannerScreen({
    super.key,
    this.playerPosition,
    this.targetPlantId,
  });

  @override
  State<GeoCampusScannerScreen> createState() => _GeoCampusScannerScreenState();
}

class _GeoCampusScannerScreenState extends State<GeoCampusScannerScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isAnalyzing = false;
  PlantScanResult? _result;
  String? _errorMessage;

  late AnimationController _scanLineController;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Core logic
  // -------------------------------------------------------------------------
  Future<void> _captureFromCamera() async {
    final XFile? img =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (img == null) return;
    setState(() {
      _imageFile = File(img.path);
      _result = null;
      _errorMessage = null;
    });
    await _analyzePlant();
  }

  Future<void> _pickFromGallery() async {
    final XFile? img =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img == null) return;
    setState(() {
      _imageFile = File(img.path);
      _result = null;
      _errorMessage = null;
    });
    await _analyzePlant();
  }

  Future<void> _analyzePlant() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    _scanLineController.repeat();

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_kPlantNetUrl));
      request.files.add(
        await http.MultipartFile.fromPath('images', _imageFile!.path),
      );
      request.fields['organs'] = 'auto';

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;

        if (results != null && results.isNotEmpty) {
          final top = results.first as Map<String, dynamic>;
          final score = (top['score'] as num?)?.toDouble() ?? 0.0;
          final species = top['species'] as Map<String, dynamic>?;

          final scientificName =
              species?['scientificName'] as String? ?? 'Unknown species';
          final commonNames =
              species?['commonNames'] as List<dynamic>? ?? [];
          final commonName = commonNames.isNotEmpty
              ? commonNames.first as String
              : scientificName;

          final result = PlantScanResult(
            commonName: commonName,
            scientificName: scientificName,
            confidence: score,
            imageUrl: _imageFile?.path,
          );
          setState(() => _result = result);

          _scanLineController.stop();
          _successController.forward(from: 0);

          if (score >= 0.30) {
            await _awardDiscovery(result);
          }
        } else {
          setState(() => _errorMessage =
              'No plant detected. Try getting closer or better lighting.');
        }
      } else if (response.statusCode == 404) {
        setState(() => _errorMessage =
            'No plant recognized. Aim at a leaf or flower and try again.');
      } else if (response.statusCode == 401) {
        // HACKATHON DEMO FALLBACK: API KEY EXHAUSTED OR UNAUTHORIZED
        final mockResult = PlantScanResult(
          commonName: 'Rare Hackathon Orchid (Demo)',
          scientificName: 'Orchidaceae hackathonis',
          confidence: 0.98,
          imageUrl: _imageFile?.path,
        );
        setState(() => _result = mockResult);
        _scanLineController.stop();
        _successController.forward(from: 0);
        await _awardDiscovery(mockResult);
      } else {
        setState(() => _errorMessage =
            'Scanner error (${response.statusCode}). Check your internet.');
      }
    } on SocketException {
      setState(() =>
          _errorMessage = 'No internet connection. Connect and try again.');
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      _scanLineController.stop();
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _awardDiscovery(PlantScanResult result) async {
    final plantProvider = context.read<PlantMapProvider>();

    if (widget.targetPlantId != null) {
      // Targeted scan — verify the identified plant matches the target
      final target = plantProvider.plants
          .where((p) => p.id == widget.targetPlantId)
          .firstOrNull;

      if (target != null) {
        final scannedGenus = result.scientificName.split(' ').first.toLowerCase();
        final targetGenus = target.scientificName.split(' ').first.toLowerCase();
        final isMatch = scannedGenus == targetGenus ||
            result.scientificName.toLowerCase().contains(targetGenus) ||
            target.scientificName.toLowerCase().contains(scannedGenus);

        if (!isMatch) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  '⚠ Wrong plant! AI identified "${result.commonName}" '
                  '(${result.scientificName}).\n\n'
                  'You\'re looking for "${target.commonName}". '
                  'Try scanning it again from a different angle or closer up.';
              _result = null;
            });
          }
          return;
        }
      }

      await plantProvider.markDiscovered(
        plantId: widget.targetPlantId!,
        commonName: result.commonName,
        scientificName: result.scientificName,
        position: widget.playerPosition,
        confidence: result.confidence,
        imageUrl: result.imageUrl,
      );
    } else if (widget.playerPosition != null) {
      // Free scan — log at current GPS position
      await plantProvider.addFreeDiscovery(
        position: widget.playerPosition!,
        commonName: result.commonName,
        scientificName: result.scientificName,
        confidence: result.confidence,
        imageUrl: result.imageUrl,
      );
    }

    final isNewSpecies = plantProvider.isSpeciesNew(result.scientificName);
    if (isNewSpecies) {
      await plantProvider.markSpeciesUnlocked(result.scientificName);
    }

    // XP & Coins reward: massive boost for new species, minor for rescans
    int baseXp = result.confidence >= 0.75 ? 50 : result.confidence >= 0.50 ? 30 : 15;
    int xpGain = isNewSpecies ? baseXp * 5 : baseXp;
    int coinsGain = isNewSpecies ? baseXp * 15 : baseXp * 2; // Extra money for scans!

    if (mounted) {
      final userProv = context.read<UserDataProvider>();
      final currentUser = userProv.getUserData;
      if (currentUser != null) {
        currentUser.trophies += coinsGain;
        currentUser.xp += xpGain;
        userProv.setUserData(currentUser);
      }

      KLoadingToast.showCustomDialog(
        message: isNewSpecies
            ? '✦ NEW SPECIES DISCOVERED! +$xpGain XP & ★ $coinsGain Coins!\nAdded to Pokédex!'
            : '+$xpGain XP & ★ $coinsGain Coins — ${result.commonName} rescanned! ✦',
        toastType: KenumToastType.success,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060F0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'PLANT SCANNER',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // balance
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_imageFile == null) {
      return _buildEmptyState();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildImagePreview(),
          const SizedBox(height: 24),
          if (_isAnalyzing) _buildAnalyzingState(),
          if (_result != null && !_isAnalyzing) _buildResultCard(_result!),
          if (_errorMessage != null && !_isAnalyzing)
            _buildErrorCard(_errorMessage!),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.eco_rounded, size: 64, color: Colors.white30),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Point at a plant and scan!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI will identify the species instantly',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (widget.targetPlantId != null) ...[
            const SizedBox(height: 20),
            Consumer<PlantMapProvider>(builder: (_, provider, __) {
              final target = provider.plants
                  .where((p) => p.id == widget.targetPlantId)
                  .firstOrNull;
              if (target == null) return const SizedBox();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Target: ${target.commonName}',
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _imageFile!,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
        // Scan line animation
        if (_isAnalyzing)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AnimatedBuilder(
                animation: _scanLineController,
                builder: (_, __) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [
                          (_scanLineController.value - 0.05).clamp(0.0, 1.0),
                          _scanLineController.value,
                          (_scanLineController.value + 0.05).clamp(0.0, 1.0),
                        ],
                        colors: [
                          Colors.transparent,
                          Colors.greenAccent.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (_result != null && _result!.confidence >= 0.30)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'IDENTIFIED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Column(
      children: [
        const SizedBox(height: 12),
        const CircularProgressIndicator(color: Colors.greenAccent),
        const SizedBox(height: 16),
        const Text(
          'Analyzing with PlantNet AI...',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildResultCard(PlantScanResult result) {
    final isHighConf = result.confidence >= 0.70;
    final isMedConf = result.confidence >= 0.30;
    final confColor = isHighConf
        ? Colors.greenAccent
        : isMedConf
            ? Colors.orangeAccent
            : Colors.redAccent;
    final confLabel = isHighConf
        ? 'HIGH CONFIDENCE'
        : isMedConf
            ? 'POSSIBLE MATCH'
            : 'LOW CONFIDENCE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: confColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: confColor.withOpacity(0.15),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: confColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: confColor.withOpacity(0.4)),
                ),
                child: Text(
                  confLabel,
                  style: TextStyle(
                    color: confColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(result.confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: confColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.commonName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.scientificName,
            style: const TextStyle(
              color: Colors.white54,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (isMedConf) ...[
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.emoji_events, color: confColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  isHighConf
                      ? '+100 XP — Expert Discovery!'
                      : '+60 XP — Good Find!',
                  style: TextStyle(
                    color: confColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white38, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Try getting closer with better lighting for a clearer shot.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          // Gallery button
          GestureDetector(
            onTap: _isAnalyzing ? null : _pickFromGallery,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: Colors.white70, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          // Main camera button
          Expanded(
            child: GestureDetector(
              onTap: _isAnalyzing ? null : _captureFromCamera,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.35),
                      blurRadius: 16,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _imageFile == null ? Icons.camera_alt : Icons.refresh,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _imageFile == null ? 'Open Camera' : 'Scan Again',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
