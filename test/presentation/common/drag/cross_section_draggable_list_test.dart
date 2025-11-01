import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/presentation/common/drag/cross_section_draggable_list.dart';
import 'package:granoflow/presentation/common/drag/draggable_list_controller.dart';
import 'package:granoflow/presentation/common/drag/draggable_list_delegate.dart';

void main() {
  group('CrossSectionDraggableList', () {
    late TestDelegate<String> delegate;
    late DraggableListController<String> controller;
    late List<String> items;

    setUp(() {
      items = ['Item 1', 'Item 2', 'Item 3'];
      delegate = TestDelegate();
      controller = DraggableListController<String>();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should display all items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CrossSectionDraggableList<String>(
                items: items,
                delegate: delegate,
                controller: controller,
                sectionId: 'test-section',
              ),
            ),
          ),
        ),
      );

      // Wait for the AnimatedList to build
      await tester.pump();
      
      // Verify all items are displayed
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('should handle empty list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CrossSectionDraggableList<String>(
                items: [],
                delegate: delegate,
                controller: controller,
                sectionId: 'test-section',
              ),
            ),
          ),
        ),
      );

      // Should build without errors
      expect(find.byType(AnimatedList), findsOneWidget);
    });

    testWidgets('should show promote target when enabled', 
        (WidgetTester tester) async {
      delegate.promoteTargetWidget = Container(
        key: const Key('promote-target'),
        height: 50,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CrossSectionDraggableList<String>(
                items: items,
                delegate: delegate,
                controller: controller,
                sectionId: 'test-section',
                showPromoteTarget: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('promote-target')), findsOneWidget);
    });

    testWidgets('should not show promote target when disabled', 
        (WidgetTester tester) async {
      delegate.promoteTargetWidget = Container(
        key: const Key('promote-target'),
        height: 50,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CrossSectionDraggableList<String>(
                items: items,
                delegate: delegate,
                controller: controller,
                sectionId: 'test-section',
                showPromoteTarget: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('promote-target')), findsNothing);
    });

    testWidgets('should handle drag within list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              child: CrossSectionDraggableList<String>(
                items: items,
                delegate: delegate,
                controller: controller,
                sectionId: 'test-section',
              ),
            ),
          ),
        ),
      );

      // Long press on Item 2 to start dragging
      final item2 = find.text('Item 2');
      final item2Center = tester.getCenter(item2);
      
      await tester.startGesture(item2Center);
      await tester.pump(const Duration(milliseconds: 600)); // Wait for long press
      
      // Verify drag started
      expect(controller.isDragging, isTrue);
      expect(controller.draggedItem, equals('Item 2'));
      expect(controller.draggedIndex, equals(1));
    });
  });
}

/// Test implementation of DraggableListDelegate
class TestDelegate<T extends Object> extends DraggableListDelegate<T> {
  final List<T> reorderedItems = [];
  final List<T> acceptedExternalItems = [];
  final Map<T, T> childParentPairs = {};
  final List<T> promotedItems = [];
  Widget? promoteTargetWidget;

  @override
  bool canReorder(T item, int oldIndex, int newIndex) => true;

  @override
  Future<void> onReorder(T item, int oldIndex, int newIndex) async {
    reorderedItems.add(item);
  }

  @override
  bool canAcceptExternal(T draggedItem, int targetIndex) => true;

  @override
  Future<void> onAcceptExternal(T draggedItem, int targetIndex) async {
    acceptedExternalItems.add(draggedItem);
  }

  @override
  bool canMakeChild(T draggedItem, T targetItem) => true;

  @override
  Future<void> onMakeChild(T draggedItem, T targetItem) async {
    childParentPairs[draggedItem] = targetItem;
  }

  @override
  bool canPromoteToRoot(T item) => true;

  @override
  Future<void> onPromoteToRoot(T item) async {
    promotedItems.add(item);
  }

  @override
  String getItemId(T item) => item.toString();

  @override
  Widget buildItem(BuildContext context, T item, int index, 
      Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text(item.toString()),
      ),
    );
  }

  @override
  Widget? buildPromoteTarget(BuildContext context) => promoteTargetWidget;
}
