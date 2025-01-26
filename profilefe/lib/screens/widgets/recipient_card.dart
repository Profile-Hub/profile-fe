import 'package:flutter/material.dart';
import '../../models/AllReciptentmodel.dart';

class RecipientCard extends StatelessWidget {
  final Recipient recipient;

  const RecipientCard({Key? key, required this.recipient}) : super(key: key);

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
              'Name: ${recipient.firstname} ${recipient.middleName ?? ''} ${recipient.lastname}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildInfoRow('Age', recipient.age?.toString() ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow('Gender', recipient.gender ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow('City', recipient.city ?? 'N/A'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildInfoRow('State', recipient.state ?? 'N/A'),
                SizedBox(width: 7),
                Text('|', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 7),
                _buildInfoRow('Country', recipient.country ?? 'N/A'),
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
