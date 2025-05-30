import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medrhythms/myuipages/medrhythmslogo.dart';
import 'package:medrhythms/userappactions/jsonexport.dart';
import 'package:medrhythms/myuipages/bottombar.dart';

/**
 * A page where users can select export options for their data, including the time period for exporting the session data.
 * It allows the user to choose between exporting all data or selecting a custom date range for export.
 */
class ExportSettingsPage extends StatefulWidget {
  @override
  _ExportSettingsPageState createState() => _ExportSettingsPageState();
}

class _ExportSettingsPageState extends State<ExportSettingsPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedOption = 'All'; // Default option
  Bottombar bb = Bottombar();

  /**
   * Opens a Cupertino date picker modal to allow the user to select a date.
   * 
   * @param context [BuildContext] The context in which the date picker is displayed.
   * @param isFromDate [bool] A flag to determine if the selected date is the "from" date or the "to" date.
   */
  void _selectDate(BuildContext context, bool isFromDate) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 250,
            color: Colors.white,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initialDate,
              minimumDate: firstDate,
              maximumDate: lastDate,
              onDateTimeChanged: (DateTime date) {
                setState(() {
                  if (isFromDate) {
                    _fromDate = date;
                  } else {
                    _toDate = date;
                  }
                });
              },
            ),
          ),
    );
  }

  /**
   * Exports the user session data based on the selected option (either "All" or a specific date range).
   * Displays appropriate feedback via SnackBars based on success or error.
   */
  void _exportData() async {
    if (_selectedOption == 'Select Time Periods') {
      if (_fromDate != null && _toDate != null) {
        if (_fromDate!.isAfter(_toDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('From date cannot be after To date')),
          );
          return;
        }
        // Call the JSON export logic
        await exportUserSessionDataAsJson(
          startDate: _fromDate,
          endDate: _toDate,
          exportType: _selectedOption,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Data exported successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both From and To dates')),
        );
      }
    } else {
      try {
        // Call the JSON export logic for "All" option
        await exportUserSessionDataAsJson(
          startDate: _fromDate,
          endDate: _toDate,
          exportType: _selectedOption,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All data exported successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MedRhythmsAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                // "All" option radio button
                Radio<String>(
                  value: 'All',
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value!;
                    });
                  },
                ),
                Text('All'),
                SizedBox(width: 16),
                // "Select Time Periods" option radio button
                Radio<String>(
                  value: 'Select Time Periods',
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value!;
                    });
                  },
                ),
                Text('Select Time Periods'),
              ],
            ),
            if (_selectedOption == 'Select Time Periods') ...[
              SizedBox(height: 16),
              Text(
                'Select Date Range:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'From: ${_fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : 'Not selected'}',
                  ),
                  CupertinoButton(
                    child: Text('Select From Date'),
                    onPressed: () => _selectDate(context, true),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'To: ${_toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : 'Not selected'}',
                  ),
                  CupertinoButton(
                    child: Text('Select To Date'),
                    onPressed: () => _selectDate(context, false),
                  ),
                ],
              ),
            ],
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () => _exportData(),
                child: Text('Export'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bb,
    );
  }
}
