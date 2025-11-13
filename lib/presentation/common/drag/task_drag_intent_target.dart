import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';

import 'standard_drag_target.dart';

/// 拖拽目标渲染风格
enum TaskDragTargetStyle { surface, insertion }

/// 拖拽上下文，用于日志与调试
class TaskDragIntentMeta {
  const TaskDragIntentMeta({
    required this.page,
    required this.targetType,
    this.targetId,
    this.section,
    this.targetTaskId,
  });

  final String page;
  final String targetType;
    final String? targetId;
  final String? section;
    final String? targetTaskId;
}

/// 拖拽执行结果
class TaskDragIntentResult {
  const TaskDragIntentResult._internal({
    required this.success,
    this.parentId,
    this.sortIndex,
    this.dueDate,
    this.clearParent = false,
    this.reminderCode,
    Map<String, String>? reminderArgs,
    this.blockReasonKey,
    this.blockLogTag,
  }) : reminderArgs = reminderArgs ?? const {};

  const TaskDragIntentResult.success({
      String? parentId,
    double? sortIndex,
    DateTime? dueDate,
    bool clearParent = false,
    String? reminderCode,
    Map<String, String>? reminderArgs,
  }) : this._internal(
         success: true,
         parentId: parentId,
         sortIndex: sortIndex,
         dueDate: dueDate,
         clearParent: clearParent,
         reminderCode: reminderCode,
         reminderArgs: reminderArgs,
       );

  const TaskDragIntentResult.blocked({
    required String blockReasonKey,
    String? blockLogTag,
    String? reminderCode,
    Map<String, String>? reminderArgs,
  }) : this._internal(
         success: false,
         blockReasonKey: blockReasonKey,
         blockLogTag: blockLogTag,
         reminderCode: reminderCode,
         reminderArgs: reminderArgs,
       );

  final bool success;
    final String? parentId;
  final double? sortIndex;
  final DateTime? dueDate;
  final bool clearParent;
  final String? reminderCode;
  final Map<String, String> reminderArgs;
  final String? blockReasonKey;
  final String? blockLogTag;

  bool get isBlocked => !success;
}

typedef TaskDragIntentCanAccept =
    bool Function(Task draggedTask, WidgetRef ref);
typedef TaskDragIntentPerformer =
    Future<TaskDragIntentResult> Function(
      Task draggedTask,
      WidgetRef ref,
      BuildContext context,
      AppLocalizations? l10n,
    );
typedef TaskDragHoverCallback = void Function(bool isHovering, WidgetRef ref);
typedef TaskDragResultCallback =
    void Function(
      Task draggedTask,
      TaskDragIntentResult result,
      WidgetRef ref,
      BuildContext context,
      AppLocalizations? l10n,
    );

/// Inbox / Tasks 共用的拖拽目标组件
class TaskDragIntentTarget extends ConsumerStatefulWidget {
  const TaskDragIntentTarget.surface({
    super.key,
    required this.meta,
    required this.canAccept,
    required this.onPerform,
    required this.child,
    this.onHover,
    this.onResult,
    this.hoverColor,
    this.borderRadius,
  }) : style = TaskDragTargetStyle.surface,
       insertionType = null,
       showWhenIdle = false,
       insertionChild = null,
       useMargin = true;

  const TaskDragIntentTarget.insertion({
    super.key,
    required this.meta,
    required this.canAccept,
    required this.onPerform,
    required this.insertionType,
    this.onHover,
    this.onResult,
    this.insertionChild,
    this.showWhenIdle = false,
    this.useMargin = true,
  }) : style = TaskDragTargetStyle.insertion,
       hoverColor = null,
       borderRadius = null,
       child = null;

  final TaskDragTargetStyle style;
  final TaskDragIntentMeta meta;
  final TaskDragIntentCanAccept canAccept;
  final TaskDragIntentPerformer onPerform;
  final TaskDragHoverCallback? onHover;
  final TaskDragResultCallback? onResult;

  // surface-specific
  final Widget? child;
  final Color? hoverColor;
  final BorderRadius? borderRadius;

  // insertion-specific
  final InsertionType? insertionType;
  final Widget? insertionChild;
  final bool showWhenIdle;
  final bool useMargin;

  @override
  ConsumerState<TaskDragIntentTarget> createState() =>
      _TaskDragIntentTargetState();
}

class _TaskDragIntentTargetState extends ConsumerState<TaskDragIntentTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case TaskDragTargetStyle.surface:
        return _buildSurface(context);
      case TaskDragTargetStyle.insertion:
        return _buildInsertion(context);
    }
  }

  Widget _buildSurface(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    // hoverColor 和 borderRadius 不再使用，因为子任务功能已禁用，不显示 hover 效果

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        // 子任务功能已禁用，不接受任何拖拽
        return false;
      },
      onAcceptWithDetails: (details) async {
        // 不会执行到这里，因为 onWillAcceptWithDetails 总是返回 false
        await _handleAccept(details.data, context, l10n);
      },
      onMove: (_) {
        // 不接受拖拽时不触发 hover 效果
        // 不调用 _handleHover
      },
      onLeave: (_) {
        // 不接受拖拽时不触发 hover 效果
        // 不调用 _handleHover
      },
      builder: (context, candidate, rejected) {
        // 由于 onWillAcceptWithDetails 总是返回 false，candidate 总是为空
        // 因此不会显示 hover 效果
        return widget.child!;
      },
    );
  }

  Widget _buildInsertion(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return StandardDragTarget<Task>(
      type: widget.insertionType ?? InsertionType.between,
      showWhenIdle: widget.showWhenIdle,
      useMargin: widget.useMargin,
      child: widget.insertionChild,
      onHoverChanged: (isHovering) {
        _handleHover(isHovering);
        if (isHovering) {
          _log('hover:enter');
        } else {
          _log('hover:leave');
        }
      },
      canAccept: (dragged) {
        final can = widget.canAccept(dragged, ref);
        _log('onWillAccept', dragged: dragged, extras: {'can': can});
        return can;
      },
      onAccept: (dragged) async {
        await _handleAccept(dragged, context, l10n);
      },
    );
  }

  Future<void> _handleAccept(
    Task dragged,
    BuildContext context,
    AppLocalizations? l10n,
  ) async {
    _log('onAccept:start', dragged: dragged);
    try {
      final result = await widget.onPerform(dragged, ref, context, l10n);
      if (!mounted) return;
      if (result.isBlocked) {
        _log(
          'accept:blocked',
          dragged: dragged,
          extras: {
            if (result.blockLogTag != null) 'reason': result.blockLogTag,
            'message': result.blockReasonKey,
          },
        );
      } else {
        _log('accept:success', dragged: dragged);
      }
      widget.onResult?.call(dragged, result, ref, context, l10n);
    } catch (error, stackTrace) {
      _log('accept:error', dragged: dragged, extras: {'error': '$error'});
      if (kDebugMode) {
        debugPrint('$stackTrace');
      }
    } finally {
      _log('onAccept:end', dragged: dragged);
      _handleHover(false);
    }
  }

  void _handleHover(bool isHovering) {
    if (_isHovering == isHovering) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isHovering = isHovering;
    });
    widget.onHover?.call(isHovering, ref);
  }

  void _log(
    String event, {
    Task? dragged,
    Map<String, Object?> extras = const {},
  }) {
    if (!kDebugMode) return;
    final meta = widget.meta;
    final buffer = StringBuffer('[DnD] {event: $event, page: ${meta.page}');
    buffer.write(', tgtType: ${meta.targetType}');
    if (meta.targetId != null) {
      buffer.write(', tgtId: ${meta.targetId}');
    }
    if (meta.targetTaskId != null) {
      buffer.write(', tgtTask: ${meta.targetTaskId}');
    }
    if (meta.section != null) {
      buffer.write(', section: ${meta.section}');
    }
    if (dragged != null) {
      buffer.write(', src: ${dragged.id}');
    }
    if (extras.isNotEmpty) {
      extras.forEach((key, value) {
        if (value == null) return;
        buffer.write(', $key: $value');
      });
    }
    buffer.write('}');
    debugPrint(buffer.toString());
  }
}
