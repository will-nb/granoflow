import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'preference_service.dart';

/// 计时器音频播放服务
/// 
/// 负责播放背景音，所有音频播放都受用户设置控制
class ClockAudioService {
  ClockAudioService({
    required PreferenceService preferenceService,
  }) : _preferenceService = preferenceService {
    _tickPlayer = AudioPlayer();
    _alertPlayer = AudioPlayer();
    _initPreferenceListener();
  }

  final PreferenceService _preferenceService;
  
  // 音频播放器
  late final AudioPlayer _tickPlayer;  // 背景音播放器
  late final AudioPlayer _alertPlayer; // 提醒音播放器（已废弃，不再使用）
  
  // 背景音相关
  Timer? _tickTimer;
  bool _isTickSoundEnabled = true;
  bool _isTickSoundPlaying = false;
  
  // 提醒音相关（已废弃，不再使用）
  bool _hasPlayed10MinuteWarning = false;
  bool _hasPlayed5MinuteWarning = false;
  bool _hasPlayedCompletionSound = false;
  
  // 音频文件路径
  static const String _tickSoundPath = 'assets/sounds/default-clock.wav';
  static const String _alert10MinPath = 'assets/sounds/di.wav';
  static const String _alert5MinPath = 'assets/sounds/di.wav';
  static const String _completionSoundPath = 'assets/sounds/dieline.wav';

  /// 初始化设置监听
  void _initPreferenceListener() {
    _preferenceService.watch().listen((preference) {
      _isTickSoundEnabled = preference.clockTickSoundEnabled;
      // 如果用户关闭了声音，立即停止播放
      if (!_isTickSoundEnabled && _isTickSoundPlaying) {
        stopTickSound();
      }
    });
  }

  /// 开始播放背景音
  /// 
  /// 每0.5秒播放一次（一秒钟响两次），模拟闹钟背景音
  /// 只有在用户设置开启时才会播放
  /// 
  /// 直接启动定时器，延迟0.5秒开始，但所有声音之间的间隔都是均匀的0.5秒
  void startTickSound() {
    if (!_isTickSoundEnabled) {
      return;
    }
    
    if (_isTickSoundPlaying) {
      return;
    }
    
    _isTickSoundPlaying = true;
    
    // 直接启动定时器，每0.5秒播放一次（一秒钟响两次）
    // Timer.periodic 会在0.5秒后首次触发，之后每0.5秒触发一次
    // 这样所有声音之间的间隔都是均匀的0.5秒
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_isTickSoundEnabled && _isTickSoundPlaying) {
        _playTickSound();
      }
    });
  }

  /// 停止播放背景音
  void stopTickSound() {
    _isTickSoundPlaying = false;
    _tickTimer?.cancel();
    _tickTimer = null;
    _tickPlayer.stop();
  }

  /// 播放背景音（内部方法）
  Future<void> _playTickSound() async {
    if (!_isTickSoundEnabled) {
      return;
    }
    
    try {
      await _tickPlayer.play(AssetSource(_tickSoundPath.replaceFirst('assets/', '')));
    } catch (e) {
      // 忽略播放错误，不影响计时器运行
    }
  }

  /// 播放10分钟提醒音（已废弃，不再使用）
  /// 
  /// 倒计时还剩10分钟时调用，播放一次 di.wav
  /// 只播放一次（防止重复触发）
  @Deprecated('提醒音功能已移除，不再使用')
  Future<void> play10MinuteWarning() async {
    if (!_isTickSoundEnabled || _hasPlayed10MinuteWarning) {
      return;
    }
    
    _hasPlayed10MinuteWarning = true;
    try {
      await _alertPlayer.play(AssetSource(_alert10MinPath.replaceFirst('assets/', '')));
    } catch (e) {
      // 忽略播放错误
    }
  }

  /// 播放5分钟提醒音（已废弃，不再使用）
  /// 
  /// 倒计时还剩5分钟时调用，连续播放两次 di.wav（间隔500ms）
  /// 只播放一次（防止重复触发）
  @Deprecated('提醒音功能已移除，不再使用')
  Future<void> play5MinuteWarning() async {
    if (!_isTickSoundEnabled || _hasPlayed5MinuteWarning) {
      return;
    }
    
    _hasPlayed5MinuteWarning = true;
    try {
      final soundPath = _alert5MinPath.replaceFirst('assets/', '');
      // 播放第一次
      await _alertPlayer.play(AssetSource(soundPath));
      
      // 等待500ms后播放第二次
      await Future.delayed(const Duration(milliseconds: 500));
      await _alertPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // 忽略播放错误
    }
  }

  /// 播放完成提醒音（已废弃，不再使用）
  /// 
  /// 倒计时完成时调用，播放一次 dieline.wav
  /// 只播放一次（防止重复触发）
  @Deprecated('提醒音功能已移除，不再使用')
  Future<void> playCompletionSound() async {
    if (!_isTickSoundEnabled || _hasPlayedCompletionSound) {
      return;
    }
    
    _hasPlayedCompletionSound = true;
    try {
      await _alertPlayer.play(AssetSource(_completionSoundPath.replaceFirst('assets/', '')));
    } catch (e) {
      // 忽略播放错误
    }
  }

  /// 重置提醒音状态
  /// 
  /// 在开始新的计时会话时调用，重置所有提醒音标志
  void resetAlertFlags() {
    _hasPlayed10MinuteWarning = false;
    _hasPlayed5MinuteWarning = false;
    _hasPlayedCompletionSound = false;
  }

  /// 释放资源
  void dispose() {
    stopTickSound();
    _tickPlayer.dispose();
    _alertPlayer.dispose();
  }
}

