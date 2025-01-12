import 'package:flutter/material.dart';
import '../../models/doner_filter_model.dart';
class DonorFilterWidget extends StatefulWidget {
  final Function(DonorFilter) onFilterChanged;

  const DonorFilterWidget({Key? key, required this.onFilterChanged}) : super(key: key);

  @override
  _DonorFilterWidgetState createState() => _DonorFilterWidgetState();
}

class _DonorFilterWidgetState extends State<DonorFilterWidget> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedState;
  String? _selectedCity;
  double? _selectedRadius;
  RangeValues _ageRange = RangeValues(18, 70);
  String? _selectedGender;
  bool? _isOrganDonor;

  final List<double> radiusOptions = [50, 100, 200];

  void _applyFilters() {
    if (_formKey.currentState!.validate()) {
      widget.onFilterChanged(DonorFilter(
        state: _selectedState,
        city: _selectedCity,
        radius: _selectedRadius,
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        gender: _selectedGender,
        isOrganDonor: _isOrganDonor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Donors', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            
            // State Dropdown
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: InputDecoration(labelText: 'State'),
              items: ['State 1', 'State 2', 'State 3'] // Replace with actual states
                  .map((state) => DropdownMenuItem(
                        value: state,
                        child: Text(state),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedState = value),
            ),
            SizedBox(height: 12),

            // City Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: InputDecoration(labelText: 'City'),
              items: ['City 1', 'City 2', 'City 3'] // Replace with actual cities
                  .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCity = value),
            ),
            SizedBox(height: 12),

            // Radius Selection
            Text('Radius (km)'),
            Wrap(
              spacing: 8,
              children: radiusOptions
                  .map((radius) => ChoiceChip(
                        label: Text('${radius.toInt()} km'),
                        selected: _selectedRadius == radius,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRadius = selected ? radius : null;
                          });
                        },
                      ))
                  .toList(),
            ),
            SizedBox(height: 12),

            // Age Range Slider
            Text('Age Range: ${_ageRange.start.round()} - ${_ageRange.end.round()}'),
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 70,
              divisions: 52,
              labels: RangeLabels(
                _ageRange.start.round().toString(),
                _ageRange.end.round().toString(),
              ),
              onChanged: (values) => setState(() => _ageRange = values),
            ),
            SizedBox(height: 12),

            // Gender Selection
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(labelText: 'Gender'),
              items: ['Male', 'Female', 'Other']
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            SizedBox(height: 12),

            // Organ Donor Switch
            Row(
              children: [
                Text('Organ Donor'),
                Switch(
                  value: _isOrganDonor ?? false,
                  onChanged: (value) => setState(() => _isOrganDonor = value),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}