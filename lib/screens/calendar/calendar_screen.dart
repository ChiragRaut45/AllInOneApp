import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import '../../providers/note_provider.dart';
import 'add_note_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);

    final dateKey = selectedDay.toString().split(" ")[0];
    final note = noteProvider.getNote(dateKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Diary"),

        /// 📅 MONTH/YEAR PICKER BUTTON
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: focusedDay,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setState(() {
                  focusedDay = picked;
                  selectedDay = picked;
                });
              }
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddNoteScreen(date: dateKey)),
          );
        },
      ),

      body: Column(
        children: [
          /// 📅 CALENDAR
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),

            focusedDay: focusedDay,

            selectedDayPredicate: (day) => isSameDay(selectedDay, day),

            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },

            /// ⭐ DOT MARKER LOGIC
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final key = day.toString().split(" ")[0];
                final hasNote = noteProvider.getNote(key).isNotEmpty;

                if (hasNote) {
                  return Positioned(
                    bottom: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }

                return const SizedBox();
              },
            ),

            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),

          const SizedBox(height: 10),

          /// 📝 NOTE PREVIEW
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: note.isEmpty
                  ? const Center(
                      child: Text(
                        "No note for this day",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateKey,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        Expanded(
                          child: SingleChildScrollView(child: Text(note)),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
