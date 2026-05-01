import 'package:app/src/features/debts/presentation/pages/add_payment_page.dart';
import 'package:app/src/features/debts/presentation/pages/debt_detail_page.dart';
import 'package:app/src/features/debts/presentation/pages/debt_form_page.dart';
import 'package:app/src/features/debts/presentation/pages/debt_list_page.dart';
import 'package:app/src/features/catalog/presentation/pages/category_form_page.dart';
import 'package:app/src/features/catalog/presentation/pages/category_manager_page.dart';
import 'package:app/src/features/catalog/presentation/pages/subcategory_form_page.dart';
import 'package:app/src/features/catalog/presentation/pages/subcategory_manager_page.dart';
import 'package:app/src/features/catalog/presentation/pages/unit_form_page.dart';
import 'package:app/src/features/catalog/presentation/pages/unit_manager_page.dart';
import 'package:app/src/features/more/presentation/pages/backup_page.dart';
import 'package:app/src/features/more/presentation/pages/reports_page.dart';
import 'package:app/src/features/more/presentation/pages/settings_page.dart';
import 'package:app/src/features/products/presentation/pages/product_detail_page.dart';
import 'package:app/src/features/products/presentation/pages/product_form_page.dart';
import 'package:app/src/features/products/presentation/pages/product_list_page.dart';
import 'package:app/src/features/proformas/presentation/pages/proforma_detail_page.dart';
import 'package:app/src/features/proformas/presentation/pages/proforma_form_page.dart';
import 'package:app/src/features/proformas/presentation/pages/proforma_list_page.dart';
import 'package:app/src/shared/presentation/main_shell_page.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2563EB);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const _SplashPage(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        splashFactory: InkSparkle.splashFactory,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        cardTheme: CardThemeData(
          elevation: 1,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dialogTheme: const DialogThemeData(
          surfaceTintColor: Colors.transparent,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.inverseSurface,
          contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            minimumSize: const Size(0, 52),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            minimumSize: const Size(0, 52),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            minimumSize: const Size(0, 52),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: false,
          filled: true,
          fillColor: colorScheme.surfaceContainerHigh,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case MainShellPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const MainShellPage(),
            );
          case ReportsPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ReportsPage(),
            );
          case SettingsPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SettingsPage(),
            );
          case '/catalog-settings':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SettingsPage(),
            );
          case BackupPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const BackupPage(),
            );
          case CategoryManagerPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const CategoryManagerPage(),
            );
          case CategoryFormPage.routeName:
            final args = settings.arguments as CategoryFormArgs?;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => CategoryFormPage(args: args),
            );
          case SubcategoryManagerPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SubcategoryManagerPage(),
            );
          case SubcategoryFormPage.routeName:
            final args = settings.arguments as SubcategoryFormArgs?;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => SubcategoryFormPage(args: args),
            );
          case UnitManagerPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const UnitManagerPage(),
            );
          case UnitFormPage.routeName:
            final args = settings.arguments as UnitFormArgs?;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => UnitFormPage(args: args),
            );
          case ProductListPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ProductListPage(),
            );
          case ProductFormPage.routeName:
            final args = settings.arguments as ProductFormArgs?;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProductFormPage(args: args),
            );
          case ProductDetailPage.routeName:
            final args = settings.arguments as ProductDetailArgs;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProductDetailPage(args: args),
            );
          case ProformaListPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ProformaListPage(),
            );
          case ProformaFormPage.routeName:
            final args = settings.arguments as ProformaFormArgs;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => ProformaFormPage(args: args),
            );
          case ProformaDetailPage.routeName:
            final args = settings.arguments as ProformaDetailArgs;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => ProformaDetailPage(args: args),
            );
          case DebtListPage.routeName:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const DebtListPage(),
            );
          case DebtFormPage.routeName:
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => const DebtFormPage(),
            );
          case DebtDetailPage.routeName:
            final args = settings.arguments as DebtDetailArgs;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => DebtDetailPage(args: args),
            );
          case AddPaymentPage.routeName:
            final args = settings.arguments as AddPaymentArgs;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => AddPaymentPage(
                receivableId: args.receivableId,
                maxPrincipalAmount: args.maxPrincipalAmount,
                maxInterestAmount: args.maxInterestAmount,
              ),
            );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainShellPage(),
        );
      },
    );
  }
}

class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_didNavigate) return;
      _didNavigate = true;

      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainShellPage(),
          settings: const RouteSettings(name: MainShellPage.routeName),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 140,
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 18),
                SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
