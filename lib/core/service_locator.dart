import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';

// استيراد جميع الخدمات
import 'package:flutter_timezone/flutter_timezone.dart';
import 'services/theme_service.dart';
import 'services/page_management_service.dart';
import 'services/security_service.dart';
import 'features/dashboard/services/dashboard_settings_service.dart';
import 'features/dashboard/services/navigation_service.dart';
import 'features/dashboard/services/screen_time_service.dart';
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
import 'features/worship/services/knowledge_service.dart' as worship_knowledge;
import 'features/worship/services/node_service.dart';
import 'features/health/services/health_service.dart';
import 'features/health/services/sleep_service.dart';
import 'features/health/services/analytics_service.dart';
import 'features/learning/services/study_service.dart';
import 'features/profile/services/user_service.dart';
import 'features/auth/services/auth_service.dart';
import 'features/personal_matters/services/personal_matters_service.dart';
import 'features/learning/services/study_session_service.dart';
import 'features/learning/services/memo_service.dart';
import 'features/learning/services/knowledge_service.dart' as learning_knowledge;
import 'features/library/services/library_service.dart';
import 'features/profile/services/life_link_service.dart';
import 'features/worship/services/zad_service.dart';
import 'services/quick_link_service.dart';
import 'features/dashboard/services/pattern_analysis_service.dart';

final getIt = GetIt.instance;

/// 🚀 تهيئة سريعة فقط للخدمات الأساسية
Future<void> initializeEssentialServices() async {
  // تهيئة Hive
  import 'package:hive_flutter/hive_flutter.dart';
  await Hive.initFlutter();

  // الخدمات الأساسية فقط (التي تحتاجها التطبيق للبدء)
  await ThemeService.init();
  await PageManagementService.init();
  await DashboardSettingsService.init();
  await QuickLinkService.init();
  await NavigationService.init();
  await SecurityService.init(); // ✅ تشفير

  // تهيئة الوقت
  await initializeDateFormatting('ar_SA', null);
  await initializeDateFormatting('en_US', null);

  // تسجيل الخدمات الأساسية في Service Locator
  getIt.registerSingleton<ThemeService>(ThemeService());
  getIt.registerSingleton<SecurityService>(SecurityService());
  getIt.registerSingleton<PageManagementService>(PageManagementService());
}

/// 🔗 تهيئة باقي الخدمات بطريقة كسولة (Lazy)
/// تُستدعى عند الحاجة الفعلية للخدمة
Future<void> ensureServiceInitialized(String serviceName) async {
  switch (serviceName) {
    case 'UserService':
      if (!getIt.isRegistered<UserService>()) {
        await UserService.init();
        getIt.registerSingleton<UserService>(UserService());
      }
      break;
    case 'AuthService':
      if (!getIt.isRegistered<AuthService>()) {
        await AuthService.init();
        getIt.registerSingleton<AuthService>(AuthService());
      }
      break;
    case 'HabitService':
      if (!getIt.isRegistered<HabitService>()) {
        await HabitService.init();
        getIt.registerSingleton<HabitService>(HabitService());
      }
      break;
    case 'TaskService':
      if (!getIt.isRegistered<TaskService>()) {
        await TaskService.init();
        getIt.registerSingleton<TaskService>(TaskService());
      }
      break;
    case 'RoutineService':
      if (!getIt.isRegistered<RoutineService>()) {
        await RoutineService.init();
        getIt.registerSingleton<RoutineService>(RoutineService());
      }
      break;
    case 'ProgressService':
      if (!getIt.isRegistered<ProgressService>()) {
        await ProgressService.init();
        getIt.registerSingleton<ProgressService>(ProgressService());
      }
      break;
    case 'NotificationService':
      if (!getIt.isRegistered<NotificationService>()) {
        await NotificationService.init();
        getIt.registerSingleton<NotificationService>(NotificationService());
      }
      break;
    case 'IncrementalHabitService':
      if (!getIt.isRegistered<IncrementalHabitService>()) {
        await IncrementalHabitService.init();
        getIt.registerSingleton<IncrementalHabitService>(IncrementalHabitService());
      }
      break;
    case 'EntertainmentService':
      if (!getIt.isRegistered<EntertainmentService>()) {
        await EntertainmentService.init();
        getIt.registerSingleton<EntertainmentService>(EntertainmentService());
      }
      break;
    case 'WorshipService':
      if (!getIt.isRegistered<WorshipService>()) {
        await WorshipService.init();
        getIt.registerSingleton<WorshipService>(WorshipService());
      }
      break;
    case 'JournalService':
      if (!getIt.isRegistered<JournalService>()) {
        await JournalService.init();
        getIt.registerSingleton<JournalService>(JournalService());
      }
      break;
    case 'SecretService':
      if (!getIt.isRegistered<SecretService>()) {
        await SecretService.init();
        getIt.registerSingleton<SecretService>(SecretService());
      }
      break;
    case 'AddictionService':
      if (!getIt.isRegistered<AddictionService>()) {
        await AddictionService.init();
        getIt.registerSingleton<AddictionService>(AddictionService());
      }
      break;
    case 'HealthService':
      if (!getIt.isRegistered<HealthService>()) {
        await HealthService.init();
        getIt.registerSingleton<HealthService>(HealthService());
      }
      break;
    case 'SleepService':
      if (!getIt.isRegistered<SleepService>()) {
        await SleepService.init();
        getIt.registerSingleton<SleepService>(SleepService());
      }
      break;
    case 'AnalyticsService':
      if (!getIt.isRegistered<AnalyticsService>()) {
        await AnalyticsService.init();
        getIt.registerSingleton<AnalyticsService>(AnalyticsService());
      }
      break;
    case 'StudyService':
      if (!getIt.isRegistered<StudyService>()) {
        await StudyService.init();
        getIt.registerSingleton<StudyService>(StudyService());
      }
      break;
    case 'StudySessionService':
      if (!getIt.isRegistered<StudySessionService>()) {
        await StudySessionService.init();
        getIt.registerSingleton<StudySessionService>(StudySessionService());
      }
      break;
    case 'MemoService':
      if (!getIt.isRegistered<MemoService>()) {
        await MemoService.init();
        getIt.registerSingleton<MemoService>(MemoService());
      }
      break;
    case 'LibraryService':
      if (!getIt.isRegistered<LibraryService>()) {
        await LibraryService.init();
        getIt.registerSingleton<LibraryService>(LibraryService());
      }
      break;
    case 'PersonalMattersService':
      if (!getIt.isRegistered<PersonalMattersService>()) {
        await PersonalMattersService.init();
        getIt.registerSingleton<PersonalMattersService>(PersonalMattersService());
      }
      break;
    case 'LifeLinkService':
      if (!getIt.isRegistered<LifeLinkService>()) {
        await LifeLinkService.init();
        getIt.registerSingleton<LifeLinkService>(LifeLinkService());
      }
      break;
    case 'ZadService':
      if (!getIt.isRegistered<ZadService>()) {
        await ZadService.init();
        getIt.registerSingleton<ZadService>(ZadService());
      }
      break;
    case 'ScreenTimeService':
      if (!getIt.isRegistered<ScreenTimeService>()) {
        await ScreenTimeService.init();
        getIt.registerSingleton<ScreenTimeService>(ScreenTimeService());
      }
      break;
    case 'PatternAnalysisService':
      if (!getIt.isRegistered<PatternAnalysisService>()) {
        await PatternAnalysisService.init();
        getIt.registerSingleton<PatternAnalysisService>(PatternAnalysisService());
      }
      break;
  }
}

/// 🔥 دالة مساعدة للحصول على الخدمة مع تهيئتها تلقائياً
Future<T> getService<T>(String serviceName) async {
  await ensureServiceInitialized(serviceName);
  return getIt<T>();
}

