import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/sections_placeholder.dart';
import '../features/discipline/habits_screen.dart';
import '../features/discipline/quick_tasks_screen.dart';
import '../features/discipline/daily_routine_screen.dart';
import '../features/discipline/progress_screen.dart';
import '../features/discipline/incremental_habits_screen.dart';
import '../features/discipline/entertainment_screen.dart';
import '../features/profile/life_links_screen.dart';
import '../features/personal_matters/wissal_screen.dart';
import '../features/personal_matters/khaznati_screen.dart';
import '../features/worship/worship_screen.dart';
import '../features/worship/zad_maad_screen.dart';
import '../features/worship/journal_screen.dart';
import '../features/worship/secret_with_god_screen.dart';
import '../features/worship/addiction_screen.dart';
import '../features/worship/knowledge_screen.dart';
import '../features/health/nutrition_screen.dart';
import '../features/health/workout_screen.dart';
import '../features/health/sleep_intelligence_screen.dart';
import '../features/health/health_dashboard_screen.dart';
import '../features/learning/linked_study_screen.dart';
import '../features/learning/study_sessions_screen.dart';
import '../features/learning/dialogues_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/auth/video_splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/services/auth_service.dart';

import '../features/library/library_screen.dart';
import '../features/library/library_choice_screen.dart';
import '../features/library/pdf_viewer_screen.dart';
import '../features/library/video_player_screen.dart';
import '../features/library/models/library_models.dart';
import '../features/browser/conscious_browser_screen.dart';

class AppRouter {
  static String get initialLocation {
    // البدء بصفحة الترحيب
    return '/welcome';
  }

  static final router = GoRouter(
    initialLocation: initialLocation, 
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const VideoSplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      // 1. الجانب العقلي (mental)
      GoRoute(
        path: '/discipline',
        builder: (context, state) => const SectionScreen(title: 'الجانب العقلي', sectionKey: 'mental'),
        routes: [
          GoRoute(path: 'habits', builder: (context, state) => const HabitsScreen()),
          GoRoute(path: 'quick-tasks', builder: (context, state) => const QuickTasksScreen()),
          GoRoute(path: 'daily-routine', builder: (context, state) => const DailyRoutineScreen()),
          GoRoute(path: 'progress', builder: (context, state) => const ProgressScreen()),
          GoRoute(path: 'incremental-habits', builder: (context, state) => const IncrementalHabitsScreen()),
          GoRoute(path: 'wissal', builder: (context, state) => const WissalScreen()),
          GoRoute(path: 'khaznati', builder: (context, state) => const KhaznatiScreen()),
          GoRoute(path: 'entertainment', builder: (context, state) => const EntertainmentScreen()),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const SectionScreen(title: 'الملف الشخصي', sectionKey: 'profile'),
        routes: [],
      ),
      // 2. الجانب الروحي (spiritual)
      GoRoute(
        path: '/worship',
        builder: (context, state) => const SectionScreen(title: 'الجانب الروحي', sectionKey: 'spiritual'),
        routes: [
          GoRoute(path: 'prayers', builder: (context, state) => const WorshipScreen()),
          GoRoute(path: 'zad-maad', builder: (context, state) => const ZadMaadScreen()),
          GoRoute(path: 'journal', builder: (context, state) => const JournalScreen()),
          GoRoute(path: 'sir-ma3-allah', builder: (context, state) => const SecretWithGodScreen()),
          GoRoute(path: 'awadho-allah', builder: (context, state) => const AddictionScreen()),
          GoRoute(path: 'hujja-li', builder: (context, state) => const KnowledgeScreen()),
        ],
      ),
      // 3. الجانب البدني (physical)
      GoRoute(
        path: '/health',
        builder: (context, state) => const SectionScreen(title: 'الجانب البدني', sectionKey: 'physical'),
        routes: [
          GoRoute(path: 'nutrition', builder: (context, state) => const NutritionScreen()),
          GoRoute(path: 'sports', builder: (context, state) => const WorkoutScreen()),
          GoRoute(path: 'sleep', builder: (context, state) => const SleepIntelligenceScreen()),
          GoRoute(path: 'care', builder: (context, state) => const HealthDashboardScreen()),
        ],
      ),
      // 4. الجانب النفسي (psychological)
      GoRoute(
        path: '/learning',
        builder: (context, state) => const SectionScreen(title: 'الجانب النفسي', sectionKey: 'psychological'),
        routes: [
          GoRoute(path: 'linked-studies', builder: (context, state) => const LinkedStudyScreen()),
          GoRoute(path: 'study-sessions', builder: (context, state) => const StudySessionsScreen()),
          GoRoute(path: 'dialogues', builder: (context, state) => const DialoguesScreen()),
        ],
      ),
      GoRoute(
        path: '/library-choice',
        builder: (context, state) => const LibraryChoiceScreen(),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(libraryType: LibraryType.pdf),
        routes: [
          GoRoute(
            path: 'viewer',
            builder: (context, state) {
              if (state.extra == null) return const Scaffold(body: Center(child: Text('Error: No data provided')));
              final extra = state.extra as Map<String, dynamic>;
              return PDFViewerScreen(
                filePath: extra['path'] ?? '',
                title: extra['name'] ?? 'Viewer',
                fileId: extra['id'] ?? '',
                initialPage: extra['currentUnit'] ?? 0,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/video-library',
        builder: (context, state) => const LibraryScreen(libraryType: LibraryType.video),
        routes: [
          GoRoute(
            path: 'video-player',
            builder: (context, state) {
              if (state.extra == null) return const Scaffold(body: Center(child: Text('Error: No data provided')));
              final extra = state.extra as Map<String, dynamic>;
              return VideoPlayerScreen(
                filePaths: [extra['path'] ?? ''],
                titles: [extra['name'] ?? 'Video Player'],
                initialIndex: 0,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/audio-library',
        builder: (context, state) => const LibraryScreen(libraryType: LibraryType.audio),
      ),
      GoRoute(
        path: '/browser',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ConsciousBrowserScreen(initialUrl: extra?['url']);
        },
      ),
    ],
  );
}
