import 'package:flutter/material.dart';
import '../../models/AllReciptentmodel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecipientCard extends StatelessWidget {
  final Recipient recipient;

  const RecipientCard({Key? key, required this.recipient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
     final localizations = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${localizations.name}: ${recipient.firstname} ${recipient.middleName ?? ''} ${recipient.lastname}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                if (recipient.isVerified == true) 
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          localizations.verified,
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildInfoRow('${localizations.age}', recipient.age?.toString() ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow('${localizations.gender_label}', recipient.gender ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow('${localizations.city_label}', recipient.city ?? 'N/A'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildInfoRow('${localizations.state_label}', recipient.state ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow('${localizations.country_label}', recipient.country ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}