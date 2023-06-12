import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/edit_label_page.dart';

class EditCorrespondentPage extends StatelessWidget {
  final Correspondent correspondent;
  const EditCorrespondentPage({super.key, required this.correspondent});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => EditLabelCubit(
        context.read(),
      ),
      child: Builder(builder: (context) {
        return EditLabelPage<Correspondent>(
          label: correspondent,
          fromJsonT: Correspondent.fromJson,
          onSubmit: (context, label) =>
              context.read<EditLabelCubit>().replaceCorrespondent(label),
          onDelete: (context, label) =>
              context.read<EditLabelCubit>().removeCorrespondent(label),
          canDelete: LocalUserAccount.current.paperlessUser.hasPermission(
            PermissionAction.delete,
            PermissionTarget.correspondent,
          ),
        );
      }),
    );
  }
}
