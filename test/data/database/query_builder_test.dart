import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/database/query_builder.dart';

void main() {
  group('QueryDescriptor', () {
    test('should create descriptor with conditions and orders', () {
      final descriptor = QueryDescriptor(
        conditions: [
          FieldCondition(
            field: 'status',
            operator: 'equals',
            value: 'active',
          ),
          FieldCondition(
            field: 'createdAt',
            operator: 'greaterThan',
            value: DateTime(2024, 1, 1),
          ),
        ],
        orders: [
          OrderDescriptor(field: 'createdAt', descending: true),
          OrderDescriptor(field: 'title', descending: false),
        ],
        limit: 10,
        offset: 5,
      );

      expect(descriptor.conditions.length, equals(2));
      expect(descriptor.orders.length, equals(2));
      expect(descriptor.limit, equals(10));
      expect(descriptor.offset, equals(5));
    });

    test('describe should return human-readable string', () {
      final descriptor = QueryDescriptor(
        conditions: [
          FieldCondition(
            field: 'status',
            operator: 'equals',
            value: 'active',
          ),
        ],
        orders: [
          OrderDescriptor(field: 'createdAt', descending: true),
        ],
        limit: 10,
      );

      final description = descriptor.describe();
      expect(description, contains('status'));
      expect(description, contains('equals'));
      expect(description, contains('createdAt'));
      expect(description, contains('desc'));
      expect(description, contains('10'));
    });

    test('toJson should serialize descriptor', () {
      final descriptor = QueryDescriptor(
        conditions: [
          FieldCondition(
            field: 'status',
            operator: 'equals',
            value: 'active',
          ),
        ],
        orders: [
          OrderDescriptor(field: 'createdAt', descending: true),
        ],
        limit: 10,
        offset: 5,
      );

      final json = descriptor.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['conditions'], isA<List>());
      expect(json['orders'], isA<List>());
      expect(json['limit'], equals(10));
      expect(json['offset'], equals(5));
    });
  });

  group('FieldCondition', () {
    test('should create condition with all fields', () {
      final condition = FieldCondition(
        field: 'title',
        operator: 'contains',
        value: 'test',
      );

      expect(condition.field, equals('title'));
      expect(condition.operator, equals('contains'));
      expect(condition.value, equals('test'));
    });

    test('toString should return readable representation', () {
      final condition = FieldCondition(
        field: 'status',
        operator: 'equals',
        value: 'active',
      );

      final str = condition.toString();
      expect(str, contains('status'));
      expect(str, contains('equals'));
      expect(str, contains('active'));
    });
  });

  group('OrderDescriptor', () {
    test('should create order descriptor', () {
      final order = OrderDescriptor(
        field: 'createdAt',
        descending: true,
      );

      expect(order.field, equals('createdAt'));
      expect(order.descending, isTrue);
    });

    test('toString should return readable representation', () {
      final order = OrderDescriptor(
        field: 'title',
        descending: false,
      );

      final str = order.toString();
      expect(str, contains('title'));
      expect(str, contains('descending: false'));
    });
  });
}
