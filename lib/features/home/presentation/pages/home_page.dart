import 'package:cached_network_image/cached_network_image.dart';
import 'package:carepass/core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../bloc/home_bloc.dart';
import '../widgets/home_widgets.dart';

part '../widgets/home/home_content.dart';
part '../widgets/home/home_app_bar.dart';
part '../widgets/home/default_logo_icon.dart';
part '../widgets/home/quick_actions_grid.dart';
part '../widgets/home/home_loading_skeleton.dart';
part '../widgets/home/skeleton_box.dart';
part '../widgets/home/home_error_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) return const _HomeLoadingSkeleton();
            if (state is HomeError) {
              return _HomeErrorView(message: state.message);
            }
            if (state is HomeLoaded) return _HomeContent(state: state);
            return const SizedBox.shrink();
          },
        ),
      ),
      // ✅ Replaced the AI Assistant FAB with a WhatsApp support
      // button. The AI feature's files/route are left completely
      // untouched — just not linked from here anymore.
      floatingActionButton: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is! HomeLoaded) return const SizedBox.shrink();
          return const Padding(
            padding: EdgeInsets.only(bottom: AppDimens.paddingSM),
            child: WhatsAppSupportFab(),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─────────────────────────────────────────────
//  Home Content
// ─────────────────────────────────────────────
