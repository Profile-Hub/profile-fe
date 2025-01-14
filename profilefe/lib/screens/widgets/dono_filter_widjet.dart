import 'package:flutter/material.dart';
import '../../models/doner_filter_model.dart';
import '../../services/location_api_service.dart';
import '../../models/location_models.dart' as LocationModels;

class DonorFilterWidget extends StatefulWidget {
  final Function(DonorFilter) onFilterChanged;
  final VoidCallback onClose;

  const DonorFilterWidget({
    Key? key, 
    required this.onFilterChanged,
    required this.onClose, 
  }) : super(key: key);

  @override
  State<DonorFilterWidget> createState() => _DonorFilterWidgetState();
}

class _DonorFilterWidgetState extends State<DonorFilterWidget> {
  final _formKey = GlobalKey<FormState>();
  final LocationApiService _locationService = LocationApiService();
  
  // Location related state
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  List<LocationModels.Country> _countries = [];
  List<LocationModels.State> _states = [];
  List<LocationModels.City> _cities = [];
  bool _isLoadingLocations = false;

  // Other filter state
  double? _selectedRadius;
  RangeValues _ageRange = RangeValues(18, 70);
  String? _selectedGender;
  final List<double> radiusOptions = [50, 100, 200];

  // Organ donation related state
  final Map<String, List<String>> organCategories = {
    'Organs': [
      'Heart', 'Lungs', 'Liver', 'Kidneys', 'Pancreas', 'Intestines'
    ],
    'Tissues': [
      'Corneas', 'Skin', 'Heart Valves', 'Blood Vessels and Veins',
      'Tendons and Ligaments', 'Bone'
    ],
    'Reproductive Organs': [
      'Uterus', 'Ovaries', 'Eggs (Oocytes)', 'Fallopian Tubes',
      'Testicles', 'Sperm'
    ],
    'Other Donations': [
      'Bone Marrow and Stem Cells', 'Blood and Plasma', 'Umbilical Cord Blood'
    ],
    'Living Donations': [
      'Liver Segment', 'Kidney', 'Lung Lobe', 'Skin (partial)',
      'Bone Marrow and Stem Cells (regenerative)'
    ],
  };
  Map<String, bool> selectedOrgans = {};

  @override
  void initState() {
    super.initState();
    _initializeOrganSelection();
    _loadCountries();
  }

  void _initializeOrganSelection() {
    organCategories.forEach((category, organs) {
      organs.forEach((organ) {
        selectedOrgans[organ] = false;
      });
    });
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingLocations = true);
    try {
      final countries = await _locationService.getCountries();
      setState(() {
        _countries = countries;
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load countries: $e')),
        );
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _loadStates(String countryName) async {
    setState(() => _isLoadingLocations = true);
    try {
      final states = await _locationService.getStates(countryName);
      setState(() {
        _states = states;
        _selectedState = null;
        _cities = [];
        _selectedCity = null;
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load states: $e')),
        );
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _loadCities(String stateName) async {
    setState(() => _isLoadingLocations = true);
    try {
      final cities = await _locationService.getCities(stateName);
      setState(() {
        _cities = cities;
        _selectedCity = null;
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cities: $e')),
        );
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  void _applyFilters() {
    if (_formKey.currentState!.validate()) {
      List<String> selectedOrgansList = selectedOrgans.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      widget.onFilterChanged(DonorFilter(
        state: _selectedState,
        city: _selectedCity,
        radius: _selectedRadius,
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        gender: _selectedGender,
        organsDonating: selectedOrgansList,
      ));
      
      widget.onClose(); 
    }
  }

  Widget _buildLocationDropdowns() {
    return Column(
      children: [
        // Country Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          decoration: InputDecoration(
            labelText: 'Country',
            enabled: !_isLoadingLocations,
          ),
          items: _countries.map((country) => DropdownMenuItem(
            value: country.name,
            child: Text(country.name),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCountry = value);
              _loadStates(value);
            }
          },
        ),
        SizedBox(height: 12),

        // State Dropdown
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: InputDecoration(
            labelText: 'State',
            enabled: !_isLoadingLocations && _selectedCountry != null,
          ),
          items: _states.map((state) => DropdownMenuItem(
            value: state.name,
            child: Text(state.name),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedState = value);
              _loadCities(value);
            }
          },
        ),
        SizedBox(height: 12),

        // City Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: 'City',
            enabled: !_isLoadingLocations && _selectedState != null,
          ),
          items: _cities.map((city) => DropdownMenuItem(
            value: city.name,
            child: Text(city.name),
          )).toList(),
          onChanged: (value) => setState(() => _selectedCity = value),
        ),
      ],
    );
  }

  Widget _buildOrganSelection() {
    return ExpansionPanelList(
      elevation: 1,
      expandedHeaderPadding: EdgeInsets.zero,
      children: organCategories.entries.map((category) {
        return ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return ListTile(
              title: Text(category.key),
            );
          },
          body: Column(
            children: category.value.map((organ) {
              return CheckboxListTile(
                title: Text(organ),
                value: selectedOrgans[organ] ?? false,
                onChanged: (bool? value) {
                  setState(() {
                    selectedOrgans[organ] = value ?? false;
                  });
                },
              );
            }).toList(),
          ),
          isExpanded: true,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Donors', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              
              _buildLocationDropdowns(),
              SizedBox(height: 16),

              // Radius Selection
              Text('Radius (km)'),
              Wrap(
                spacing: 8,
                children: radiusOptions.map((radius) => ChoiceChip(
                  label: Text('${radius.toInt()} km'),
                  selected: _selectedRadius == radius,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRadius = selected ? radius : null;
                    });
                  },
                )).toList(),
              ),
              SizedBox(height: 16),

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
              SizedBox(height: 16),

              // Gender Selection
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other'].map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                )).toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              SizedBox(height: 16),

              // Organ Selection
              Text('Select Organs for Donation', 
                style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              _buildOrganSelection(),
              SizedBox(height: 16),

              // Apply Button
              SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoadingLocations ? null : _applyFilters,
                        child: Text('Apply Filters'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}