// lib/utils/db_utils.dart
import 'dart:convert';

/// Utility class for database operations
class DbUtils {
  /// Create WHERE clause from a map of conditions
  static String buildWhereClause(Map<String, dynamic> conditions) {
    if (conditions.isEmpty) return '';
    
    final clauses = conditions.entries.map((entry) {
      final key = entry.key;
      final value = entry.value;
      
      if (value == null) {
        return '$key IS NULL';
      } else if (value is String && value.contains('%')) {
        return '$key LIKE ?';
      } else {
        return '$key = ?';
      }
    }).join(' AND ');
    
    return clauses;
  }

  /// Extract argument values from conditions
  static List<dynamic> extractArguments(Map<String, dynamic> conditions) {
    return conditions.entries
        .where((entry) => entry.value != null)
        .map((entry) => entry.value)
        .toList();
  }

  /// Build ORDER BY clause
  static String buildOrderByClause(String? orderBy, String? orderDirection) {
    if (orderBy == null || orderBy.isEmpty) return '';
    
    final direction = (orderDirection?.toUpperCase() == 'DESC') ? 'DESC' : 'ASC';
    return 'ORDER BY $orderBy $direction';
  }

  /// Build LIMIT and OFFSET clause
  static String buildLimitOffsetClause(int? limit, int? offset) {
    String clause = '';
    
    if (limit != null) {
      clause = 'LIMIT $limit';
      
      if (offset != null) {
        clause += ' OFFSET $offset';
      }
    }
    
    return clause;
  }

  /// Sanitize SQL identifier to prevent SQL injection
  static String sanitizeSqlIdentifier(String identifier) {
    // Remove any non-alphanumeric characters except underscores
    return identifier.replaceAll(RegExp(r'[^\w]'), '');
  }

  /// Convert Dart map to SQLite compatible format
  static Map<String, dynamic> toSqliteMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    
    map.forEach((key, value) {
      if (value is DateTime) {
        // Convert DateTime to ISO string format
        result[key] = value.toIso8601String();
      } else if (value is bool) {
        // Convert boolean to 0/1 integer
        result[key] = value ? 1 : 0;
      } else if (value is Map || value is List) {
        // Convert complex objects to JSON strings
        result[key] = jsonEncode(value);
      } else {
        result[key] = value;
      }
    });
    
    return result;
  }

  /// Convert SQLite result to Dart native types
  static Map<String, dynamic> fromSqliteMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    
    map.forEach((key, value) {
      if (value is String && key.toLowerCase().contains('date')) {
        // Try to parse date strings
        try {
          result[key] = DateTime.parse(value);
        } catch (_) {
          result[key] = value;
        }
      } else if (key.toLowerCase().contains('is_') && (value is int)) {
        // Convert 0/1 to boolean for is_ prefixed fields
        result[key] = value == 1;
      } else {
        result[key] = value;
      }
    });
    
    return result;
  }

  /// Format value for SQL insertion
  static dynamic formatValueForSQL(dynamic value) {
    if (value == null) return 'NULL';
    if (value is String) return "'${escapeString(value)}'";
    if (value is DateTime) return "'${value.toIso8601String()}'";
    if (value is bool) return value ? 1 : 0;
    return value.toString();
  }

  /// Escape SQL string to prevent injection
  static String escapeString(String value) {
    return value.replaceAll("'", "''");
  }
}