import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import 'explosion_particle_painter.dart';
import '../../widgets/modern_tag.dart';

/// 标签状态
class _LabelState {
  _LabelState({
    required this.label,
    required this.key,
    // ignore: unused_element_parameter
    this.visible = true,
    // ignore: unused_element_parameter
    this.opacity = 1.0,
    // ignore: unused_element_parameter
    this.scale = 1.0,
    // ignore: unused_element_parameter
    this.offset = Offset.zero,
    // ignore: unused_element_parameter
    this.selected = false,
    // ignore: unused_element_parameter
    this.particles = const [],
  });

  final String label;
  final GlobalKey key;
  bool visible;
  double opacity;
  double scale;
  Offset offset;
  bool selected;
  List<Particle> particles;
}

/// 回顾页面开场动画组件
class ReviewOpeningAnimation extends StatefulWidget {
  const ReviewOpeningAnimation({
    super.key,
    required this.onAnimationComplete,
  });

  /// 动画完成回调
  final VoidCallback onAnimationComplete;

  @override
  State<ReviewOpeningAnimation> createState() => _ReviewOpeningAnimationState();
}

class _ReviewOpeningAnimationState
    extends State<ReviewOpeningAnimation>
    with TickerProviderStateMixin {
  // 标签列表
  final List<_LabelState> _labels = [];
  final List<GlobalKey> _labelKeys = [];

  // 动画控制器
  late AnimationController _mainController;
  late AnimationController _explosionController;

  // 当前阶段（保留用于未来扩展）
  // int _currentPhase = 0;

  // 标签位置信息（保留用于未来扩展）
  // final Map<String, Size> _labelSizes = {};
  // final Map<String, Offset> _labelPositions = {};

  @override
  void initState() {
    super.initState();

    // 初始化标签
    final labels = [
      '日报',
      '周报',
      '月报',
      '季报',
      '年报',
      '回顾',
    ];

    for (final label in labels) {
      final key = GlobalKey();
      _labelKeys.add(key);
      _labels.add(_LabelState(
        label: label,
        key: key,
      ));
    }

    // 创建主动画控制器（总时长 3.8 秒）
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    // 创建爆炸动画控制器（0.5 秒）
    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 监听主动画
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });

    // 开始动画序列
    _startAnimationSequence();
  }

  void _startAnimationSequence() {
    // 阶段1：初始展示（1秒）
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _startPhase2();
    });
  }

  void _startPhase2() {
    // 阶段2：日报消失
    _explodeLabel(0, () {
      if (!mounted) return;
      _slideRemainingLabels(0);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _startPhase3();
      });
    });
  }

  void _startPhase3() {
    // 阶段3：周报消失
    _explodeLabel(1, () {
      if (!mounted) return;
      _slideRemainingLabels(1);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _startPhase4();
      });
    });
  }

  void _startPhase4() {
    // 阶段4：月报消失
    _explodeLabel(2, () {
      if (!mounted) return;
      _slideRemainingLabels(2);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _startPhase5();
      });
    });
  }

  void _startPhase5() {
    // 阶段5：季报消失
    _explodeLabel(3, () {
      if (!mounted) return;
      _slideRemainingLabels(3);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _startPhase6();
      });
    });
  }

  void _startPhase6() {
    // 阶段6：年报消失
    _explodeLabel(4, () {
      if (!mounted) return;
      _slideRemainingLabels(4);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _startPhase7();
      });
    });
  }

  void _startPhase7() {
    // 阶段7：回顾标签选中状态
    setState(() {
      _labels[5].selected = true;
    });

    // 动画完成后触发回调
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _mainController.forward();
    });
  }

  void _explodeLabel(int index, VoidCallback onComplete) {
    if (index >= _labels.length) {
      onComplete();
      return;
    }

    final label = _labels[index];
    final context = label.key.currentContext;

    if (context == null) {
      onComplete();
      return;
    }

    // 获取标签位置和大小
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      onComplete();
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final center = position + Offset(size.width / 2, size.height / 2);

    // 生成粒子
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = primaryColor.withValues(alpha: 0.12);
    final textColor = primaryColor;

    final particles = ParticleGenerator.generateParticles(
      center: center,
      backgroundColor: backgroundColor,
      textColor: textColor,
      primaryColor: primaryColor,
      count: 8,
      labelSize: size,
    );

    setState(() {
      label.particles = particles;
      label.visible = false;
    });

    // 播放爆炸动画
    _explosionController.reset();
    _explosionController.forward().then((_) {
      setState(() {
        label.particles = [];
      });
      onComplete();
    });
  }

  void _slideRemainingLabels(int explodedIndex) {
    // 计算需要滑动的距离
    if (explodedIndex >= _labels.length - 1) {
      return;
    }

    // 获取被爆炸标签的大小
    final explodedLabel = _labels[explodedIndex];
    final context = explodedLabel.key.currentContext;
    if (context == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final slideDistance = renderBox.size.width + 8; // 标签宽度 + 间距

    // 滑动剩余标签（使用 AnimatedContainer 的 Transform.translate）
    setState(() {
      for (int i = explodedIndex + 1; i < _labels.length; i++) {
        _labels[i].offset = Offset(-slideDistance, 0);
      }
    });

    // 动画滑动回原位
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        for (int i = explodedIndex + 1; i < _labels.length; i++) {
          _labels[i].offset = Offset.zero;
        }
      });
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 标签行（使用 Row 布局）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _labels.asMap().entries.map((entry) {
                  final label = entry.value;

                  if (!label.visible && label.particles.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: label.opacity,
                    child: Transform.scale(
                      scale: label.scale,
                      child: Transform.translate(
                        offset: label.offset,
                        child: _buildLabel(context, label, primaryColor, l10n),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 粒子效果层（覆盖整个区域）
            if (_labels.any((label) => label.particles.isNotEmpty))
              Positioned.fill(
                child: CustomPaint(
                  painter: ExplosionParticlePainter(
                    particles: _labels
                        .expand((label) => label.particles)
                        .toList(),
                    animation: _explosionController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(
    BuildContext context,
    _LabelState labelState,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    // 获取本地化文本
    final localizedLabel = switch (labelState.label) {
      '日报' => l10n.reviewLabelDaily,
      '周报' => l10n.reviewLabelWeekly,
      '月报' => l10n.reviewLabelMonthly,
      '季报' => l10n.reviewLabelQuarterly,
      '年报' => l10n.reviewLabelYearly,
      '回顾' => l10n.reviewLabelReview,
      _ => labelState.label,
    };

    return Container(
      key: labelState.key,
      margin: const EdgeInsets.only(right: 8),
      child: ModernTag(
        label: localizedLabel,
        color: primaryColor,
        selected: labelState.selected,
        variant: TagVariant.pill,
        size: TagSize.medium,
        onTap: null, // 不可交互
      ),
    );
  }
}

