import 'package:flutter/material.dart';
import '../../models/AllReciptentmodel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme.dart';

class RecipientCard extends StatelessWidget {
  final Recipient recipient;

  const RecipientCard({Key? key, required this.recipient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.surfaceGrey,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${localizations.name}: ${recipient.firstname} ${recipient.middleName ?? ''} ${recipient.lastname}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (recipient.isVerified == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          localizations.verified,
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(localizations.age, recipient.age?.toString() ?? 'N/A'),
            _buildDivider(),
            _buildInfoRow(localizations.gender_label, recipient.gender ?? 'N/A'),
            _buildDivider(),
            _buildInfoRow(localizations.city_label, recipient.city ?? 'N/A'),
            _buildDivider(),
            _buildInfoRow(localizations.state_label, recipient.state ?? 'N/A'),
            _buildDivider(),
            _buildInfoRow(localizations.country_label, recipient.country ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        color: AppTheme.textGrey.withOpacity(0.5),
        thickness: 0.8,
      ),
    );
  }
}
