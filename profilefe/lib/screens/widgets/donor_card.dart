import 'package:flutter/material.dart';
import '../../models/allDoner.dart';

class DonorCard extends StatelessWidget {
  final Doner donor;

  const DonorCard({Key? key, required this.donor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    'Name: ${donor.firstname} ${donor.middleName ?? ''} ${donor.lastname}',
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
                          'Verified',
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
                _buildInfoRow('Age', donor.age?.toString() ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow('Gender', donor.gender ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow('City', donor.city ?? 'N/A'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildInfoRow('State', donor.state ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow('Country', donor.country ?? 'N/A'),
              ],
            ),
            _buildOrganDonationsRow(donor.organDonations),
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

  Widget _buildOrganDonationsRow(List<String>? organDonations) {
    if (organDonations == null || organDonations.isEmpty) {
      return _buildInfoColumn('Organ Donations', 'N/A');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organ Donations: ',
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
}