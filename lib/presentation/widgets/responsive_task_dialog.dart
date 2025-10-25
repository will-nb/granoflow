import 'package:flutter/material.dart';
import 'create_task_dialog.dart';

class ResponsiveTaskDialog extends StatelessWidget {
  const ResponsiveTaskDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用宽度决定布局方式
        if (constraints.maxWidth > 600) {
          // 宽屏模式：使用固定最大宽度，纵向和横向都居中显示
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 600,
              ),
              child: const CreateTaskDialog(),
            ),
          );
        } else {
          // 窄屏模式：使用全宽，不居中
          return const CreateTaskDialog();
        }
      },
    );
  }
}
