import 'package:flutter/material.dart';
import '../../utils/tag_utils.dart';

/// 里程碑草稿数据模型
/// 用于在创建项目时临时存储里程碑信息
class MilestoneDraft {
  MilestoneDraft()
    : titleController = TextEditingController(),
      descriptionController = TextEditingController();

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  DateTime? deadline;
  String? urgencyTag;
  String? importanceTag;
  VoidCallback? titleListener;
  bool suppressShortcut = false;

  void applyTag(String slug) {
    if (urgencyTags.contains(slug)) {
      urgencyTag = slug;
    } else if (importanceTags.contains(slug)) {
      importanceTag = slug;
    }
  }

  List<String> buildTags() {
    return <String>[];
  }

  void dispose() {
    if (titleListener != null) {
      titleController.removeListener(titleListener!);
    }
    titleController.dispose();
    descriptionController.dispose();
  }
}

