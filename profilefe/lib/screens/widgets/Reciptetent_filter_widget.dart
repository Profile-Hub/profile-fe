import 'package:flutter/material.dart';
import '../../models/Recipitent_filter_modal.dart';
import '../../services/location_api_service.dart';
import '../../models/location_models.dart' as LocationModels;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecipientFilterWidget extends StatefulWidget {
  final Function(RecipientFilter) onFilterChanged;
  final VoidCallback onClose;

  const RecipientFilterWidget({
    Key? key,
    required this.onFilterChanged,
    required this.onClose,
  }) : super(key: key);

  @override
  State<RecipientFilterWidget> createState() => _RecipientFilterWidgetState();
}

class _RecipientFilterWidgetState extends State<RecipientFilterWidget> {
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
  String? _selectedGender;
  final List<double> radiusOptions = [50, 100, 200];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingLocations = true);
     final localizations = AppLocalizations.of(context)!;

    try {
      final countries = await _locationService.getCountries();
      setState(() {
        _countries = countries;
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.counryFail}: $e')),
        );
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _loadStates(String countryName) async {
    setState(() => _isLoadingLocations = true);
     final localizations = AppLocalizations.of(context)!;

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
          SnackBar(content: Text('${localizations.stateFail}: $e')),
        );
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _loadCities(String stateName) async {
    setState(() => _isLoadingLocations = true);
     final localizations = AppLocalizations.of(context)!;

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
          SnackBar(content: Text('${localizations.cityFail}: $e')),
        );
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  void _applyFilters() {
    if (_formKey.currentState!.validate()) {
      widget.onFilterChanged(RecipientFilter(
        country: _selectedCountry,
        state: _selectedState,
        city: _selectedCity,
        radius: _selectedRadius,
        gender: _selectedGender,
      ));

      widget.onClose();
    }
  }
  void _resetFilters() {
  setState(() {
    _selectedCountry = null;
    _selectedState = null;
    _selectedCity = null;
    _selectedRadius = null;
    _selectedGender = null;
  });

}

  Widget _buildLocationDropdowns() {
     final localizations = AppLocalizations.of(context)!;
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

  @override
  Widget build(BuildContext context) {
     final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${localizations.filterRecipients}', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),

              _buildLocationDropdowns(),
              SizedBox(height: 16),

              // Radius Selection
              Text('${localizations.radius}(km)'),
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

              // Gender Selection
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(labelText:localizations.gender_label),
                items: ['Male', 'Female', 'Other'].map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                )).toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              SizedBox(height: 16),

              // Apply Button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingLocations ? null : _applyFilters,
                      icon: const Icon(Icons.check_circle),
                      label: Text(localizations.applyFilters),
                    ),
                  ),
                  const SizedBox(width: 8), // Add spacing between the buttons
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _resetFilters();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(localizations.resetFilters),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
