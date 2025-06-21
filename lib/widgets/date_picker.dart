/// A custom date picker widget that displays a styled container with a date label and a calendar icon.
///
/// When the calendar icon is pressed and the widget is enabled, a date picker dialog is shown.
/// Upon selecting a date, the [onDateSelected] callback is triggered with the selected [DateTime].
///
/// The appearance of the widget changes based on the [enabled] flag:
/// - If enabled, the background color uses the theme's primary color and the label is bold.
/// - If disabled, the background uses the theme's secondary color and the label is normal weight.
///
/// Parameters:
/// - [onDateSelected]: Callback function invoked when a date is selected.
/// - [enabled]: Determines if the date picker is interactive and styled as enabled.
///
library;

import 'package:flutter/material.dart';

class DatePicker extends StatefulWidget {
  final void Function(DateTime)? onDateSelected;
  final bool enabled;
  const DatePicker({
    super.key,
    required this.onDateSelected,
    required this.enabled,
  });

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12.0),
      decoration: BoxDecoration(
        color:
            widget.enabled
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            // Display the selected date if available, otherwise show placeholder
            _selectedDate != null
                ? "${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.year}"
                : 'MM/DD/YYYY',
            style: TextStyle(
              fontWeight: widget.enabled ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(width: 10.0),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            padding: const EdgeInsets.all(0.0),
            onPressed: () async {
              if (widget.enabled) {
                DateTime? res = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (res != null) {
                  setState(() {
                    _selectedDate = res;
                  });
                  if (widget.onDateSelected != null) {
                    widget.onDateSelected!(res);
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
