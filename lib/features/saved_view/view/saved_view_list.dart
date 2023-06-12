import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/navigation/push_routes.dart';
import 'package:paperless_mobile/core/widgets/hint_card.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/saved_view/view/saved_view_loading_sliver_list.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class SavedViewList extends StatelessWidget {
  const SavedViewList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectivity) {
        return BlocBuilder<SavedViewCubit, SavedViewState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SavedViewLoadingSliverList(),
              loading: () => const SavedViewLoadingSliverList(),
              loaded: (savedViews) {
                if (savedViews.isEmpty) {
                  return SliverToBoxAdapter(
                    child: HintCard(
                      hintText: S
                          .of(context)!
                          .createViewsToQuicklyFilterYourDocuments,
                    ),
                  );
                }
                return SliverList.builder(
                  itemBuilder: (context, index) {
                    final view = savedViews.values.elementAt(index);
                    return ListTile(
                      enabled: connectivity.isConnected,
                      title: Text(view.name),
                      subtitle: Text(
                        S.of(context)!.nFiltersSet(view.filterRules.length),
                      ),
                      onTap: () {
                        pushSavedViewDetailsRoute(context, savedView: view);
                      },
                    );
                  },
                  itemCount: savedViews.length,
                );
              },
              error: () => const SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    "An error occurred while trying to load the saved views.",
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
