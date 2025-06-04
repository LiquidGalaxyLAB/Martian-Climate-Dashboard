import 'package:flutter/material.dart';

class DatePicker extends StatelessWidget {
  final void Function(DateTime)? onDateSelected;
  final bool enabled;
  const DatePicker({
    super.key,
    required this.onDateSelected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12.0),
      decoration: BoxDecoration(
        color:
            enabled
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MM/DD/YYYY',
            style: TextStyle(
              fontWeight: enabled ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(width: 10.0),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            padding: const EdgeInsets.all(0.0),
            onPressed: () async {
              if (enabled) {
                DateTime? res = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (res != null && onDateSelected != null) {
                  onDateSelected!(res);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
