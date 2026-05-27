import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'features/discipline/services/habit_service.dart';
import 'features/discipline/services/task_service.dart';
import 'features/discipline/services/routine_service.dart';
import 'features/discipline/services/progress_service.dart';
import 'features/discipline/services/notification_service.dart';
import 'features/discipline/services/incremental_habit_service.dart';
import 'features/discipline/services/entertainment_service.dart';
import 'features/worship/services/worship_service.dart';
import 'features/worship/services/journal_service.dart';
import 'features/worship/services/secret_service.dart';
import 'features/worship/services/addiction_service.dart';
import 'features/worship/services/knowledge_service.dart'; 
import 'features/worship/services/node_service.dart'; 
import 'features/health/services/health_service.dart';
import 'features/health/services/sleep_service.dart';
import 'features/learning/services/study_service.dart';
import 'features/profile/services/user_service.dart';
import 'features/auth/services/auth_service.dart';
import 'features/personal_matters/services/personal_matters_service.dart';

import 'features/learning/services/study_session_service.dart';
import 'features/learning/services/memo_service.dart';
import 'features/learning/services/knowledge_service.dart' as learning_knowledge;
import 'core/services/theme_service.dart';
import 'core/services/page_management_service.dart';
import 'features/dashboard/services/dashboard_settings_service.dart';
import 'features/dashboard/services/navigation_service.dart';
import 'features/dashboard/services/screen_time_service.dart';
import 'features/dashboard/services/sunan_service.dart';

import 'features/browser/services/browser_service.dart';
import 'features/library/services/library_service.dart';
import 'features/profile/services/life_link_service.dart';
import 'features/worship/services/zad_service.dart';
import 'core/services/quick_link_service.dart';

import 'core/services/locale_service.dart';
import 'core/services/security_service.dart';
import 'core/services/badge_service.dart';

import 'dart:async';

import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/services.dart';

import 'features/worship/services/qiyam_service.dart';
import 'features/worship/services/season_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // السماح بتدوير الشاشة في كافة الاتجاهات
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  try {
    debugPrint("Initializing JustAudioBackground...");
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Wasariu Audio',
      androidNotificationOngoing: true,
    );
    debugPrint("JustAudioBackground initialized.");
  } catch (e) {
    debugPrint("Error initializing JustAudioBackground: $e");
  }
  
  // تهيئة Hive الأساسي
  await Hive.initFlutter();
  
  // تهيئة الإعدادات الأساسية فوراً
  await ThemeService.init();
  await LocaleService.init();
  await PageManagementService.init();
  await DashboardSettingsService.init();
  await QuickLinkService.init();
  await NavigationService.init();
  await SunanService.init();
  
  // تهيئة الخدمات بشكل متوازي لتسريع تشغيل التطبيق
  debugPrint("Initializing services in parallel...");
  
  // يجب تهيئة UserService أولاً لأن AuthService يعتمد عليه
  await UserService.init();
  
  await Future.wait([
    AuthService.init(),
    HabitService.init(),
    IncrementalHabitService.init(),
    TaskService.init(),
    RoutineService.init(),
    ProgressService.init(),
    WorshipService.init(),
    JournalService.init(),
    SecretService.init(),
    AddictionService.init(),
    HealthService.init(),
    SleepService.init(),
    StudyService.init(),
    StudySessionService.init(),
    MemoService.init(),
    learning_knowledge.KnowledgeService.init(),
    KnowledgeService.init(),
    NodeService.init(),
    LibraryService.init(),
    PersonalMattersService.init(),
    LifeLinkService.init(),
    ZadService.init(),
    EntertainmentService.init(),
    BrowserService.init(),
    ScreenTimeService.init(),
    BadgeService.init(),
    QiyamService.init(),
    SeasonService.init(),
  ]);
  debugPrint("Services initialized.");
  
  // تهيئة الإشعارات
  await NotificationService.init();
  
  // تهيئة بيانات الوقت المحلية
  await initializeDateFormatting('ar_SA', null);
  await initializeDateFormatting('en_US', null);

  runApp(const WasariuApp());
}

class WasariuApp extends StatelessWidget {
  const WasariuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (_, currentLocale, __) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeNotifier,
          builder: (_, ThemeMode currentMode, __) {
            return MaterialApp.router(
              title: 'وَسَارِعُواُ',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ar', 'SA'),
                Locale('en', 'US'),
              ],
              locale: currentLocale,
              routerConfig: AppRouter.router,
              builder: (context, child) {
                return Directionality(
                  textDirection: currentLocale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}
