import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../services/expense_service.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../screens/reports/expense_report.dart';


class ExpenseModule {
  // Register the expense service provider
  static SingleChildWidget createExpenseServiceProvider() {
    return Provider<ExpenseService>(
      create: (context) => ExpenseService(
        apiService: context.read<ApiService>(),
        databaseService: context.read<DatabaseService>(),
      ),
      dispose: (_, service) {
      },
    );
  }
  
  // Add expense module routes
  static Map<String, WidgetBuilder> createExpenseRoutes() {
    return {
      '/reports/expenses': (context) => const ExpenseReportScreen(),
      // Add more routes as needed for expense management
    };
  }
  
  // Initialize expense module in database
  static Future<void> initializeDatabaseTables(DatabaseService databaseService) async {

    final db = await databaseService.database;
    
    // Check if expenses table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='expenses'"
    );
    
    if (tables.isEmpty) {
      // Create expenses table if it doesn't exist
      await db.execute('''
      CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          expense_date TEXT NOT NULL,
          supplier_id INTEGER,
          reference_number TEXT,
          notes TEXT,
          attachment_url TEXT,
          user_id INTEGER,
          branch_id INTEGER NOT NULL,
          payment_method TEXT,
          status TEXT DEFAULT 'completed',
          created_at TEXT DEFAULT (datetime('now', 'localtime')),
          updated_at TEXT DEFAULT (datetime('now', 'localtime')),
          sync_status TEXT DEFAULT 'pending',
          FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
          FOREIGN KEY (user_id) REFERENCES users(id),
          FOREIGN KEY (branch_id) REFERENCES branches(id)
      )''');
      
      // Create expense indexes
      await db.execute('CREATE INDEX idx_expenses_date ON expenses(expense_date)');
      await db.execute('CREATE INDEX idx_expenses_category ON expenses(category)');
      await db.execute('CREATE INDEX idx_expenses_supplier ON expenses(supplier_id)');
      await db.execute('CREATE INDEX idx_expenses_branch ON expenses(branch_id)');
      await db.execute('CREATE INDEX idx_expenses_user ON expenses(user_id)');
      await db.execute('CREATE INDEX idx_expenses_status ON expenses(status)');
      await db.execute('CREATE INDEX idx_expenses_sync ON expenses(sync_status)');
      await db.execute('CREATE INDEX idx_expenses_search ON expenses(description, reference_number)');
    }
  }
  
  // Create drawer menu items for expense management
  static List<Widget> createDrawerMenuItems(BuildContext context) {
    return [
      const Divider(),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          'Financial Reports',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.bar_chart),
        title: const Text('Expense Reports'),
        onTap: () {
          Navigator.pop(context); 
          Navigator.pushNamed(context, '/reports/expenses');
        },
      ),
      //
    ];
  }
  
  // Example of how to use this module in your main.dart
  static void exampleUsage() {
    /*
    
    // In your main.dart file:
    
    void main() async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialize database service
      final databaseService = DatabaseService();
      
      // Initialize tables
      await ExpenseModule.initializeDatabaseTables(databaseService);
      
      runApp(
        MultiProvider(
          providers: [
            // Register core services
            Provider<DatabaseService>.value(value: databaseService),
            Provider<ApiService>(
              create: (_) => ApiService(baseUrl: AppConstants.apiBaseUrl),
            ),
            
            // Register auth service
            ChangeNotifierProvider<AuthService>(
              create: (context) => AuthService(
                databaseService: context.read<DatabaseService>(),
                apiService: context.read<ApiService>(),
                sharedPreferences: await SharedPreferences.getInstance(),
              ),
            ),
            
            // Register expense service
            ExpenseModule.createExpenseServiceProvider(),
            
            // Register other services...
          ],
          child: MyApp(),
        ),
      );
    }
    
    class MyApp extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          title: 'MANUK POS',
          theme: AppTheme.lightTheme,
          routes: {
            // Register core routes
            '/': (context) => SplashScreen(),
            '/login': (context) => LoginScreen(),
            '/dashboard': (context) => DashboardScreen(),
            
            // Register expense routes
            ...ExpenseModule.createExpenseRoutes(),
            
            // Register other routes...
          },
        );
      }
    }
    
    // In your app drawer:
    Drawer(
      child: ListView(
        children: [
          // App header
          DrawerHeader(...),
          
          // Main menu items
          ListTile(title: Text('Dashboard'), ...),
          ListTile(title: Text('Products'), ...),
          ListTile(title: Text('Transactions'), ...),
          
          // Expense module menu items
          ...ExpenseModule.createDrawerMenuItems(context),
          
          // Other menu items...
        ],
      ),
    )
    
    */
  }
}