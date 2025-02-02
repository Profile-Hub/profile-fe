import 'package:flutter/material.dart';
import '../../models/allDoner.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DonorCard extends StatelessWidget {
  final Doner donor;

  const DonorCard({Key? key, required this.donor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;  // Keep the localization here
    
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
                    '${localizations.name}: ${donor.firstname} ${donor.middleName ?? ''} ${donor.lastname}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                if (donor.isVerified == true) // Add null check if needed
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
                _buildInfoRow(localizations, '${localizations.age}', donor.age?.toString() ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow(localizations, '${localizations.gender_label}', donor.gender ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow(localizations, '${localizations.city_label}', donor.city ?? 'N/A'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildInfoRow(localizations, '${localizations.state_label}', donor.state ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow(localizations, '${localizations.country_label}', donor.country ?? 'N/A'),
              ],
            ),
            _buildInfoRow(localizations, '${localizations.bloodGroup}', donor.bloodGroup ?? 'N/A'),
            _buildOrganDonationsRow(localizations, donor.organDonations),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(AppLocalizations localizations, String label, String value) {
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

  Widget _buildOrganDonationsRow(AppLocalizations localizations, List<String>? organDonations) {
    if (organDonations == null || organDonations.isEmpty) {
      return _buildInfoColumn(localizations, '${localizations.organDonations}', 'N/A');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${localizations.organDonations}: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Wrap(
              spacing: 5.0,
              runSpacing: 5.0,
              children: [
                Text(
                  organDonations.join(' | '),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(AppLocalizations localizations, String label, String value) {
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
