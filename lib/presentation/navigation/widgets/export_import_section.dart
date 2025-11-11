import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/import_service.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 导出导入功能组件
class ExportImportSection extends ConsumerStatefulWidget {
  const ExportImportSection({super.key});

  @override
  ConsumerState<ExportImportSection> createState() =>
      _ExportImportSectionState();
}

class _ExportImportSectionState extends ConsumerState<ExportImportSection> {
  bool _isExporting = false;
  bool _isImporting = false;

  /// 导出数据
  Future<void> _handleExport() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final exportService = await ref.read(exportServiceProvider.future);
      final zipFile = await exportService.exportToZip();

      // 分享文件
      final l10n = AppLocalizations.of(context);
      await Share.shareXFiles(
        [XFile(zipFile.path)],
        text: l10n.exportData,
        subject: zipFile.path.split('/').last,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).exportSuccess),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).exportFailed}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  /// 导入数据
  Future<void> _handleImport() async {
    if (_isImporting) return;

    // 选择文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['flow.grano'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final filePath = result.files.single.path!;
    final file = File(filePath);

    setState(() {
      _isImporting = true;
    });

    try {
      final importService = await ref.read(importServiceProvider.future);
      final result = await importService.importFromZip(file);

      if (mounted) {
        // 显示统计信息对话框
        _showImportResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).importFailed}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  /// 显示导入结果对话框
  void _showImportResultDialog(ImportResult result) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importComplete),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow(
                l10n.importProjectsCreated,
                result.projectsCreated,
              ),
              _buildStatRow(
                l10n.importProjectsUpdated,
                result.projectsUpdated,
              ),
              _buildStatRow(
                l10n.importProjectsSkipped,
                result.projectsSkipped,
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                l10n.importMilestonesCreated,
                result.milestonesCreated,
              ),
              _buildStatRow(
                l10n.importMilestonesUpdated,
                result.milestonesUpdated,
              ),
              _buildStatRow(
                l10n.importMilestonesSkipped,
                result.milestonesSkipped,
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                l10n.importTasksCreated,
                result.tasksCreated,
              ),
              _buildStatRow(
                l10n.importTasksUpdated,
                result.tasksUpdated,
              ),
              _buildStatRow(
                l10n.importTasksSkipped,
                result.tasksSkipped,
              ),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.importErrors,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...result.errors.take(5).map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          error,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                if (result.errors.length > 5)
                  Text(
                    l10n.importMoreErrors(result.errors.length - 5),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.upload,
            color: colorScheme.primary,
          ),
          title: Text(l10n.exportData),
          subtitle: Text(l10n.exportDataDescription),
          trailing: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: _isExporting ? null : _handleExport,
        ),
        ListTile(
          leading: Icon(
            Icons.download,
            color: colorScheme.primary,
          ),
          title: Text(l10n.importData),
          subtitle: Text(l10n.importDataDescription),
          trailing: _isImporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: _isImporting ? null : _handleImport,
        ),
      ],
    );
  }
}

