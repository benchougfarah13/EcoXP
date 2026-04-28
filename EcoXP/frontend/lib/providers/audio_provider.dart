import 'package:audioplayers/audioplayers.dart';
import 'package:eco_collect/constants/kdimens.dart';
import 'package:eco_collect/constants/prefs_keys.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  double _bgMusicVolume = KDimens.defaultMusicVolume;
  String? _currentSoundAsset;
  bool _isPlaying = false;

  AudioProvider() {
    WidgetsBinding.instance.addObserver(this);
    _player.setReleaseMode(ReleaseMode.loop); // Set looping globally once
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (_isPlaying) {
        _player.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isPlaying) {
        _player.resume();
      }
    }
  }

  void playSoundForScreen(String soundAsset) async {
    if (_currentSoundAsset == soundAsset) return; // Prevent restarting same music
    
    _currentSoundAsset = soundAsset; // Lock state synchronously *before* async gaps to prevent race conditions!
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVolume = prefs.getDouble(KSharedPrefsKeys.audioVolume) ?? KDimens.defaultMusicVolume;
      
      _bgMusicVolume = savedVolume;

      if (_bgMusicVolume <= 0.0) {
        await _player.stop();
        _isPlaying = false;
      } else {
        await _player.setVolume(_bgMusicVolume);
        await _player.play(AssetSource(soundAsset));
        _isPlaying = true;
      }
    } catch (_) {}
  }

  double get getBgMusicVolume {
    return _bgMusicVolume;
  }

  void setBgMusicVolume(double newVol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(KSharedPrefsKeys.audioVolume, newVol);
      
      _bgMusicVolume = newVol;
      
      if (newVol <= 0.0) {
        await _player.stop();
        _isPlaying = false;
      } else {
        await _player.setVolume(newVol);
        if (!_isPlaying && _currentSoundAsset != null) {
          await _player.resume();
          _isPlaying = true;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  void pauseSound() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void stopSound() async {
    await _player.stop();
    _isPlaying = false;
    _currentSoundAsset = null;
    notifyListeners();
  }

  void resumeSound() async {
    if (_bgMusicVolume > 0.0) {
      await _player.resume();
      _isPlaying = true;
      notifyListeners();
    }
  }

  void reset() {
    _bgMusicVolume = KDimens.defaultMusicVolume;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }
}
