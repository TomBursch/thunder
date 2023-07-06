import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:thunder/account/account.dart';
import 'package:thunder/community/community.dart';
import 'package:thunder/community/pages/feed_page.dart';
import 'package:thunder/inbox/inbox.dart';
import 'package:thunder/search/bloc/search_bloc.dart';
import 'package:thunder/search/search.dart';

import 'package:thunder/settings/pages/about_settings_page.dart';
import 'package:thunder/settings/pages/general_settings_page.dart';
import 'package:thunder/settings/pages/gesture_settings_page.dart';
import 'package:thunder/settings/pages/theme_settings_page.dart';
import 'package:thunder/settings/settings.dart';
import 'package:thunder/thunder/thunder.dart';
import 'package:thunder/utils/fade_through_transition_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) =>
          Thunder(body: child),
      routes: <GoRoute>[
        GoRoute(
          name: 'home',
          path: '/',
          pageBuilder: (context, state) => FadeThroughTransitionPage(
            key: state.pageKey,
            name: state.name,
            child: FeedPage(
              listingType: state.extra as PostListingType?,
            ),
          ),
        ),
        GoRoute(
          name: 'search',
          path: '/search',
          pageBuilder: (context, state) => FadeThroughTransitionPage(
            key: state.pageKey,
            name: state.name,
            child: BlocProvider(
              create: (context) => SearchBloc(),
              child: const SearchPage(),
            ),
          ),
        ),
        GoRoute(
          name: 'inbox',
          path: '/inbox',
          pageBuilder: (context, state) => FadeThroughTransitionPage(
            key: state.pageKey,
            name: state.name,
            child: const InboxPage(),
          ),
        ),
        GoRoute(
          name: 'account',
          path: '/account',
          pageBuilder: (context, state) => FadeThroughTransitionPage(
            key: state.pageKey,
            name: state.name,
            child: const AccountPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      name: 'settings',
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => SettingsPage(),
      routes: <GoRoute>[
        GoRoute(
          name: 'general',
          path: 'general',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const GeneralSettingsPage();
          },
        ),
        GoRoute(
          name: 'themes',
          path: 'themes',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const ThemeSettingsPage();
          },
        ),
        GoRoute(
          name: 'gestures',
          path: 'gestures',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const GestureSettingsPage();
          },
        ),
        GoRoute(
          name: 'about',
          path: 'about',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const AboutSettingsPage();
          },
        ),
      ],
    ),
  ],
);
