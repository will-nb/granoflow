import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/common/drag/draggable_list_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('DraggableListController', () {
    late DraggableListController<String> controller;

    setUp(() {
      controller = DraggableListController<String>();
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize with empty items', () {
      expect(controller.items, isEmpty);
      expect(controller.isDragging, isFalse);
      expect(controller.draggedItem, isNull);
      expect(controller.draggedIndex, isNull);
      expect(controller.hoverIndex, isNull);
    });

    test('should initialize items correctly', () {
      final items = ['Item 1', 'Item 2', 'Item 3'];
      controller.initItems(items);

      expect(controller.items, equals(items));
      expect(controller.items.length, equals(3));
    });

    test('should update items without animation', () {
      controller.initItems(['A', 'B']);
      expect(controller.items, equals(['A', 'B']));

      controller.updateItems(['X', 'Y', 'Z']);
      expect(controller.items, equals(['X', 'Y', 'Z']));
    });

    test('should handle drag start correctly', () {
      controller.initItems(['A', 'B', 'C']);
      controller.startDrag('B', 1);

      expect(controller.isDragging, isTrue);
      expect(controller.draggedItem, equals('B'));
      expect(controller.draggedIndex, equals(1));
    });

    test('should update hover index', () {
      controller.initItems(['A', 'B', 'C']);
      
      controller.updateHoverIndex(2);
      expect(controller.hoverIndex, equals(2));

      controller.updateHoverIndex(null);
      expect(controller.hoverIndex, isNull);
    });

    test('should handle drag end correctly', () {
      controller.initItems(['A', 'B', 'C']);
      controller.startDrag('B', 1);
      controller.updateHoverIndex(2);

      controller.endDrag();

      expect(controller.isDragging, isFalse);
      expect(controller.draggedItem, isNull);
      expect(controller.draggedIndex, isNull);
      expect(controller.hoverIndex, isNull);
    });

    // Skip insert/remove tests as they require AnimatedListState
    // These would be tested in widget tests instead
    
    test('should track items correctly without AnimatedListState', () {
      controller.initItems(['A', 'B', 'C']);
      
      // Directly manipulate items for testing
      controller.updateItems(['A', 'X', 'B', 'C']);
      expect(controller.items, equals(['A', 'X', 'B', 'C']));
      
      controller.updateItems(['A', 'C']);
      expect(controller.items, equals(['A', 'C']));
    });

    test('should move item correctly when moving forward', () {
      controller.initItems(['A', 'B', 'C', 'D']);
      controller.startDrag('B', 1);
      
      controller.moveItem(1, 3); // Move B after C
      
      expect(controller.items, equals(['A', 'C', 'B', 'D']));
      expect(controller.draggedIndex, equals(2)); // Updated index
    });

    test('should move item correctly when moving backward', () {
      controller.initItems(['A', 'B', 'C', 'D']);
      controller.startDrag('C', 2);
      
      controller.moveItem(2, 1); // Move C before B
      
      expect(controller.items, equals(['A', 'C', 'B', 'D']));
      expect(controller.draggedIndex, equals(1)); // Updated index
    });

    test('should not move item when oldIndex equals newIndex', () {
      controller.initItems(['A', 'B', 'C']);
      
      controller.moveItem(1, 1);
      
      expect(controller.items, equals(['A', 'B', 'C']));
    });

    // Skip gap index test as it requires a real BuildContext
    // This would be tested in widget tests instead

    test('should notify listeners on state changes', () {
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      controller.initItems(['A', 'B', 'C']);
      expect(notificationCount, equals(1));

      controller.startDrag('B', 1);
      expect(notificationCount, equals(2));

      controller.updateHoverIndex(2);
      expect(notificationCount, equals(3));

      controller.endDrag();
      expect(notificationCount, equals(4));
    });
  });
}

