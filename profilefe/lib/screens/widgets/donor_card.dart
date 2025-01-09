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
            Text(
              'Name: ${donor.firstname} ${donor.middleName ?? ''} ${donor.lastname}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10),
            _buildInfoRow('Age', donor.age?.toString() ?? 'N/A'),
            _buildInfoRow('Gender', donor.gender ?? 'N/A'),
            _buildInfoRow('City', donor.city ?? 'N/A'),
            _buildInfoRow('State', donor.state ?? 'N/A'),
            _buildInfoRow('Country', donor.country ?? 'N/A'),
            _buildInfoRow('Usertype', donor.usertype ?? 'N/A'),
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
}