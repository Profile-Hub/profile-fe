import 'package:flutter/material.dart';
import '../models/allDoner.dart';
import '../services/getdoner_service.dart';
import 'package:intl/intl.dart'; 
import './donerDetails_screen.dart';
class DonorListPage extends StatefulWidget {
  @override
  _DonorListPageState createState() => _DonorListPageState();
}

class _DonorListPageState extends State<DonorListPage> {
  late Future<List<Doner>> _donors;

  @override
  void initState() {
    super.initState();
    _donors = fetchDonors();
  }

  Future<List<Doner>> fetchDonors() async {
    final donorService = DonnerService();
    return await donorService.getAllDoner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Donor List')),
      body: FutureBuilder<List<Doner>>(
        future: _donors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No donors found.'));
          } else {
            List<Doner> donors = snapshot.data!;
            return ListView.builder(
              itemCount: donors.length,
              itemBuilder: (context, index) {
                final donor = donors[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DonorDetailPage(donorId: donor.id))
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name:${donor.firstname} ${donor.middleName ?? ''} ${donor.lastname}'),
                          SizedBox(height: 10),
                          Text('Age: ${donor.age != null ? donor.age.toString() : 'N/A'}'),
                          Text('Gender: ${donor.gender ?? 'N/A'}'),
                          Text('City: ${donor.city ?? 'N/A'}'),
                          Text('State: ${donor.state ?? 'N/A'}'),
                          Text('Country: ${donor.country ?? 'N/A'}'),
                          Text('Usertype: ${donor.usertype ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
