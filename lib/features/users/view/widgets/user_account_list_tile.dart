import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/features/settings/view/widgets/user_avatar.dart';

class UserAccountListTile extends StatelessWidget {
  final LocalUserAccount account;

  final Widget? trailing;
  final VoidCallback? onTap;
  const UserAccountListTile({
    super.key,
    required this.account,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.maxFinite,
      child: ListTile(
        onTap: onTap,
        title: Text(account.paperlessUser.username),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.paperlessUser.fullName != null)
              Text(account.paperlessUser.fullName!),
            Text(
              account.serverUrl.replaceFirst(RegExp(r'https://?'), ''),
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ],
        ),
        isThreeLine: account.paperlessUser.fullName != null,
        leading: UserAvatar(account: account),
        trailing: trailing,
      ),
    );
  }
}
