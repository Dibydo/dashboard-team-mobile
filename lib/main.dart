import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Radio Wave Intensity', home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> globalData = [];
  final String url = 'http://monitor.yss.su:8000/json';

  @override
  void initState() {
    super.initState();
    fetchDataAndUpdateGlobalData();
  }

  void fetchDataAndUpdateGlobalData() {
    // Simulate fetching JSON data
    String jsonMain = '''
  {
    "data": [
      {
        "location": 1,
        "power": 10,
        "freq": 100,
        "time": "09:30:45",
        "date": "2023-09-21"
      },
      {
        "location": 2,
        "power": 15,
        "freq": 120,
        "time": "10:15:22",
        "date": "2023-09-21"
      },
      {
        "location": 3,
        "power": 8,
        "freq": 80,
        "time": "14:45:10",
        "date": "2023-09-22"
      }
    ]
  }
  ''';

    Map<String, dynamic> parsedJson = json.decode(jsonMain);
    List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(parsedJson['data']);

    setState(() {
      globalData = data;
    });
  }

  // Future<void> fetchDataAndUpdateGlobalData() async {
  //   final url = Uri.parse('http://monitor.yss.su:8000/json');
  //
  //   try {
  //     final response = await http.get(url);
  //
  //     if (response.statusCode == 200) {
  //       Map<String, dynamic> parsedJson = json.decode(response.body);
  //       List<Map<String, dynamic>> data =
  //       List<Map<String, dynamic>>.from(parsedJson['data']);
  //       setState(() {
  //         globalData = data;
  //       });
  //       if (kDebugMode) {
  //         print(globalData);
  //       }
  //     } else {
  //       if (kDebugMode) {
  //         print('Failed to fetch data: ${response.statusCode}');
  //       }
  //     }
  //   } catch (error) {
  //     if (kDebugMode) {
  //       print('Error: $error');
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: ListView.builder(
            itemCount: globalData.length,
            itemBuilder: (context, index) {
              final data = globalData[index];
              final id = data['location'];
              final amplitude = data['power'];
              final frequency = data['freq'];
              final datetime = data['date'] + " " + data['time'];

              return ListTile(
                  title: Text('$id'),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amplitude: $amplitude'),
                        Text('Frequency: $frequency'),
                        Text('Datetime: $datetime'),
                      ]),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => _MyGraphPage(),
                      ),
                    );
                  });
            }));
  }
}

class _MyGraphPage extends StatelessWidget {
  final Random random = Random();

  List<Map<String, dynamic>> generateRandomData() {
    List<Map<String, dynamic>> data = [];
    for (int i = 0; i < 6; i++) {
      data.add({
        'time': '2023-09-21 0$i:00:00',
        'intensity': (random.nextInt(201) - 100).toDouble(),
      });
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> data = generateRandomData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radio Wave Intensity'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30, // Adjust this value for label spacing
                  interval: 20, // Adjust this value based on your intensity range
                  getTitlesWidget: (value, meta) {
                    return Text(value
                        .toInt()
                        .toString()); // Customize label format as needed
                  },
                ),
              ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30, // Adjust this value for label spacing
                    interval: 1, // Adjust this value based on your data frequency
                    getTitlesWidget: (value, meta) {
                      // Convert value (index) to corresponding time from data
                      if (value >= 0 && value < data.length) {
                        final time = data[value.toInt()]["time"] as String;
                        return Text(time.substring(
                            11, 16)); // Display time in HH:mm format
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)), // Hide top titles
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)), // Hide right titles
              ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1),
            ),
            minX: 0,
            maxX: data.length.toDouble() - 1,
            minY: -100,
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
                color: Colors.blue,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestScreen extends StatelessWidget {
  final String url;
  final double amplitude;
  final int id;
  final double frequency;

  const RequestScreen(
      {super.key,
        required this.url,
        required this.amplitude,
        required this.id,
        required this.frequency});

  @override
  Widget build(BuildContext context) {
    final requestText = 'Requesting URL http://$url/$amplitude/$id/$frequency';

    return Scaffold(
        appBar: AppBar(
          title: const Text('Request Details'),
        ),
        body: Center(
          child: Text(requestText),
        ));
  }
}