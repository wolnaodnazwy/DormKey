import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_test/navigation/auto_unfocus.dart';
import 'package:firebase_test/navigation/user_role_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'sign_in_up/google_sign_in_cubit.dart';
import 'navigation/main_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart'; 

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

   await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

extension ContainerDecorations on BuildContext {
  BoxDecoration get containerDecoration => BoxDecoration(
        color: MyApp.textColorWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      );
}

extension CardDecorations on BuildContext {
  ShapeBorder get cardDecorationShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      );

  List<BoxShadow> get cardBoxShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryColor = Color(0xFF512DA8);
  static const Color primaryDarkColor = Color(0xFF311B92);
  static const Color primaryLightColor = Color(0xFF9575CD);
  static const Color backgroundColor = Color(0xFFEDE7F6);
  static const Color textColorBlack = Colors.black;
  static const Color textColorWhite = Colors.white;
  static const Color textColorGrey = Color(0xFF444444);
  static const Color outlineBorderColor = Color(0xFF79747E);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserRoleProvider(),
        ),
        BlocProvider(
          create: (context) => GoogleSignInCubit(),
        ),
      ],
      child: AutoUnfocus(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          supportedLocales: const [
            Locale('en'),
            Locale('pl'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainScreen(),
          theme: ThemeData(
            primaryColor: primaryColor,
            scaffoldBackgroundColor: backgroundColor,
            colorScheme: const ColorScheme(
              primary: primaryColor,
              onPrimary: textColorWhite,
              secondary: primaryDarkColor,
              onSecondary: textColorWhite,
              error: Colors.red,
              onError: textColorWhite,
              primaryContainer: primaryLightColor,
              surface: backgroundColor,
              onSurface: textColorBlack,
              brightness: Brightness.light,
              outline: textColorGrey,
              outlineVariant: outlineBorderColor,
            ),
            textTheme: const TextTheme(
              titleLarge: TextStyle(color: textColorWhite),
              titleMedium: TextStyle(color: textColorBlack),
              bodyLarge: TextStyle(color: textColorBlack),
              bodyMedium: TextStyle(color: textColorGrey),
              bodySmall: TextStyle(color: textColorGrey),
              labelLarge: TextStyle(color: textColorBlack),
              labelMedium: TextStyle(color: textColorGrey),
              headlineSmall: TextStyle(color: textColorGrey),
              headlineMedium: TextStyle(
                color: textColorBlack,
                fontWeight: FontWeight.bold,
              ),
              headlineLarge: TextStyle(color: Color(0xFF00FF2F)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryColor,
              foregroundColor: textColorWhite,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: textColorWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: const BorderSide(color: outlineBorderColor),
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: textColorWhite,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Theme.of(context).colorScheme.onPrimary,
              labelStyle: Theme.of(context).textTheme.labelLarge,
              hintStyle: Theme.of(context).textTheme.bodyMedium,
              floatingLabelStyle: const TextStyle(color: primaryColor),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: outlineBorderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade700),
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIconColor: textColorBlack,
              suffixIconColor: textColorBlack,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Theme.of(context).colorScheme.onSecondary,
              selectedItemColor: textColorBlack,
              unselectedItemColor: textColorBlack,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: primaryDarkColor,
              contentTextStyle: TextStyle(color: textColorWhite, fontSize: 14),
              behavior: SnackBarBehavior.floating,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.transparent,
              clipBehavior: Clip.antiAlias,
            ),
            dividerTheme: const DividerThemeData(
              color: outlineBorderColor,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              space: 1,
            ),
            toggleButtonsTheme: ToggleButtonsThemeData(
              textStyle: Theme.of(context).textTheme.labelLarge,
              fillColor: primaryDarkColor,
              selectedColor: textColorWhite,
              color: textColorBlack,
              selectedBorderColor: primaryDarkColor,
              borderColor: outlineBorderColor,
              borderRadius: BorderRadius.circular(25),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: textColorWhite,
              headerBackgroundColor: primaryColor,
              headerForegroundColor: textColorWhite,
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryLightColor;
                }
                return outlineBorderColor;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return textColorBlack;
                }
                return textColorWhite;
              }),
              todayBorder: const BorderSide(width: 0),
              dayForegroundColor:
                  WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.disabled)) {
                  return outlineBorderColor;
                }
                if (states.contains(WidgetState.selected)) {
                  return textColorWhite;
                }
                return textColorBlack;
              }),
              dayBackgroundColor:
                  WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor;
                }
                return Colors.transparent;
              }),
              yearForegroundColor:
                  const WidgetStatePropertyAll(outlineBorderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: textColorWhite,
              hourMinuteColor: backgroundColor,
              hourMinuteTextColor: MyApp.textColorBlack,
              dialBackgroundColor: backgroundColor,
              dialHandColor: primaryLightColor,
              dialTextColor: textColorBlack,
              entryModeIconColor: MyApp.primaryDarkColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              helpTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: MyApp.primaryDarkColor,
                    fontWeight: FontWeight.bold,
                  ),
              dayPeriodTextColor: MyApp.textColorBlack,
              dayPeriodColor: MyApp.primaryLightColor,
            ),
          ),
        ),
      ),
    );
  }
}
