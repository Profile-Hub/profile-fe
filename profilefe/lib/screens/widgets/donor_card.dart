import 'package:flutter/material.dart';
import '../../models/allDoner.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme.dart';

class DonorCard extends StatelessWidget {
  final Doner donor;

  const DonorCard({Key? key, required this.donor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
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
                      '${donor.firstname} ${donor.middleName ?? ''} ${donor.lastname}',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  if (donor.isVerifiedDocument == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: theme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            localizations.verified,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoChip(theme, Icons.cake, '${donor.age ?? "N/A"} ${localizations.age}'),
                        _buildDivider(),
                        _buildInfoChip(theme, Icons.person, donor.gender ?? 'N/A'),
                        _buildDivider(),
                        _buildInfoChip(theme, Icons.location_city, donor.city ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoChip(theme, Icons.map, donor.state ?? 'N/A'),
                        _buildDivider(),
                        _buildInfoChip(theme, Icons.public, donor.country ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildBloodGroupSection(theme, localizations, donor.bloodGroup),
              const SizedBox(height: 12),
              _buildOrganDonationsSection(theme, localizations, donor.organDonations),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: AppTheme.textGrey.withOpacity(0.3),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.primaryColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBloodGroupSection(ThemeData theme, AppLocalizations localizations, String? bloodGroup) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bloodtype, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(
            '${localizations.bloodGroup}: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            bloodGroup ?? 'N/A',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganDonationsSection(ThemeData theme, AppLocalizations localizations, List<String>? organDonations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.organDonations,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (organDonations?.isNotEmpty == true)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: organDonations!.map((organ) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  organ,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            )
          else
            Text(
              'N/A',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGrey,
              ),
            ),
        ],
      ),
    );
  }
}