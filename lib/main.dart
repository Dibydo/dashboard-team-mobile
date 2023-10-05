import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio Wave Intensity',
      home: MyHomePage()
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> data = []; // List to store the decoded JSON data
  final String url = 'http://monitor.yss.su:8000/json';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard')
      ),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final data = globalData[index];
          final id = data['id'];
          final amplitude = data['amplitude'];
          final frequency = data['frequency'];
          final datetime = data['date'] data['time'];

          return ListTile(
            title: Text('ID: $id'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amplitude: $amplitude'),
                Text('Frequency: $frequency'),
                Text('Time: $time'),
                Text('Date: $date'),
              ]
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RequestScreen(
                    url: url,
                    amplitude: amplitude,
                    id: id,
                    frequency: frequency)
                    );
                  }
                )
              );
            }
          }
        )
      )
    )
  }
}


  void fetchData() {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData);
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }

    List<Map<String, dynamic>> decodedData =
    List<Map<String, dynamic>>.from(json.decode(jsonData));
    setState(() {
      data = decodedData;
    }
  }
}

class RequestScreen extends StatelessWidget {
  final String url;
  final double amplitude;
  final int id;
  final double frequency;

  RequestScreen({
    required this.url,
    required this.amplitude,
    required this.id,
    required this.frequency
  });

  @override
  Widget build(BuildContext context) {
    final requestText = 'Requesting URL http://$url/$amplitude/$id/$frequency';

    return Scaffold(
      appBar: AppBar(
        title: Text('Request Details'),
      ),
      body: Center(
        child: Text(requestText),
      )
    );
  }

class _MyGraphPage extends State<MyGraphPage> {
  List<Map<String, dynamic>> data = []; // List to store the decoded JSON data

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() {
    // Simulate fetching JSON data
    String jsonData = '''
      "data": [
        {"time": "2023-09-21 08:00:00", "intensity": 75.5},
        {"time": "2023-09-21 08:15:00", "intensity": 80.2},
        {"time": "2023-09-21 08:30:00", "intensity": 85.1},
        {"time": "2023-09-21 08:45:00", "intensity": 79.8},
        {"time": "2023-09-21 09:00:00", "intensity": 82.3},
        {"time": "2023-09-21 09:15:00", "intensity": 77.6}
      ]
    ''';
    String jsonMain = '''
      {
    "data": [
      {
        "id": 1,
        "amplitude": 10,
        "frequency": 100,
        "time": "09:30:45",
        "date": "2023-09-21"
      },
      {
        "id": 2,
        "amplitude": 15,
        "frequency": 120,
        "time": "10:15:22",
        "date": "2023-09-21"
      },
      {
        "id": 3,
        "amplitude": 8,
        "frequency": 80,
        "time": "14:45:10",
        "date": "2023-09-22"
      }
    ]
  }
    ''';
    String jsonAmplitude = '''
      "data": [
        {"time": "2023-09-21 08:00:00", "amplitude": 75.5},
        {"time": "2023-09-21 08:15:00", "amplitude": 80.2},
        {"time": "2023-09-21 08:30:00", "amplitude": 85.1},
        {"time": "2023-09-21 08:45:00", "amplitude": 79.8},
        {"time": "2023-09-21 09:00:00", "amplitude": 82.3},
        {"time": "2023-09-21 09:15:00", "amplitude": 77.6}
      ]
    ''';
    List<Map<String, dynamic>> decodedData =
        List<Map<String, dynamic>>.from(json.decode(jsonData));
    setState(() {
      data = decodedData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Radio Wave Intensity'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: SideTitles(
                showTitles: true,
                reservedSize: 30, // Adjust this value for label spacing
                interval: 20, // Adjust this value based on your intensity range
                getTitles: (value) {
                  return value
                      .toInt()
                      .toString(); // Customize label format as needed
                },
              ),
              bottomTitles: SideTitles(
                showTitles: true,
                reservedSize: 30, // Adjust this value for label spacing
                interval: 1, // Adjust this value based on your data frequency
                getTitles: (value) {
                  // Convert value (index) to corresponding time from data
                  if (value >= 0 && value < data.length) {
                    final time = data[value.toInt()]["time"] as String;
                    return time.substring(
                        11, 16); // Display time in HH:mm format
                  }
                  return '';
                },
              ),
              topTitles: SideTitles(showTitles: false), // Hide top titles
              rightTitles: SideTitles(showTitles: false), // Hide right titles
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: 0,
            maxX: data.length.toDouble() - 1,
            minY: 0,
            maxY: 100,
            // Adjust this based on your intensity data range
            lineBarsData: [
              LineChartBarData(
                spots: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final intensity = entry.value['intensity'] as double;
                  return FlSpot(index.toDouble(), intensity);
                }).toList(),
                isCurved: true,
                colors: [Colors.blue],
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
