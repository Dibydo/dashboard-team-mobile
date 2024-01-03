import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tuple {
  late List<DateTime> datetime;
  late List<double> power;

  Tuple(this.datetime, this.power);

  void sort() {
    List<int> sortedIndices = List.generate(datetime.length, (index) => index)
      ..sort((a, b) => datetime[a].compareTo(datetime[b]));

    datetime = sortedIndices.map((index) => datetime[index]).toList();
    power = sortedIndices.map((index) => power[index]).toList();
  }
}


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

  // SharedPreferences key constants
  static const String cityNameKey = 'cityName';
  static const String freqKey = 'freq';
  static const String amountKey = 'amount';
  static const String allKey = 'all';

  String cityName = "";
  double freq = double.nan;
  String amount = "";
  bool all = false;

  TextEditingController controllerCity = TextEditingController();
  TextEditingController controllerFreq = TextEditingController();
  TextEditingController controllerAmount = TextEditingController();

  final FocusNode cityFocusNode = FocusNode();
  final FocusNode freqFocusNode = FocusNode();
  final FocusNode amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    loadStoredData();
  }

  Future<void> loadStoredData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load stored values or use defaults
    setState(() {
      cityName = prefs.getString(cityNameKey) ?? '';
      freq = prefs.getDouble(freqKey) ?? double.nan;
      amount = prefs.getString(amountKey) ?? '';
      all = prefs.getBool(allKey) ?? false;
    });

    // Update text controllers
    controllerCity.text = cityName;
    controllerFreq.text = freq.isNaN ? '' : freq.toString();
    controllerAmount.text = amount;
  }

  Future<void> updateAndSaveData() async {
    // Update the variables
    setState(() {
      cityName = controllerCity.text;
      freq = double.tryParse(controllerFreq.text) ?? double.nan;
      amount = controllerAmount.text;
      all = amount.isEmpty ? true : false;
    });

    // Save data to SharedPreferences
    await saveData();
  }

  Future<void> saveData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString(cityNameKey, cityName);
    prefs.setDouble(freqKey, freq);
    prefs.setString(amountKey, amount);
    prefs.setBool(allKey, all);
  }

  @override
  void dispose() {
    cityFocusNode.dispose();
    freqFocusNode.dispose();
    amountFocusNode.dispose();
    super.dispose();
  }

  Future<Tuple> fetchData(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> parsedJson = json.decode(response.body);
      List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(parsedJson['data']);
      Tuple extractedData = extractGraphingData(data);
      extractedData.sort();
      return extractedData;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Tuple extractGraphingData(List<Map<String, dynamic>> dataList) {
    List<DateTime> dateTimeList = [];
    List<double> powerList = [];

    for (var item in dataList) {
      String dateString = item['date'];
      String timeString = item['time'];
      double power = item['power'];

      DateTime dateTime = DateTime.parse('$dateString $timeString');

      dateTimeList.add(dateTime);
      powerList.add(power);
    }
    return Tuple(dateTimeList, powerList);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildCityInput(cityFocusNode),
            const SizedBox(height: 8.0),
            buildFreqInput(freqFocusNode),
            const SizedBox(height: 8.0),
            buildAmountInput(amountFocusNode),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (cityName.isNotEmpty && !(freq.isNaN) && (all || amount.isNotEmpty)) {
                        if (kDebugMode) {
                          print('All conditions met. Sending request.');
                        }
                        String urlStart = 'http://monitor.yss.su:8000/json/Monitor_id1/';
                        String url = '$urlStart$cityName/all/${freq.toString()}/${(amount.isEmpty ? "all" : amount.toString())}';
                        Tuple data = await fetchData(url);
                        if (kDebugMode) {
                          for (int i = 0; i < data.power.length; i++) {
                            print("$i: ${data.datetime[i]} --- ${data.power[i]}");
                          }
                        }
                        // TODO go to graph page and plot graph
                        // keep Tuple data and maybe cityName, freq, amount for display
                      } else {
                        if (kDebugMode) {
                          print('Some required fields are missing.');
                        }
                        if (cityName.isEmpty) {
                          cityFocusNode.requestFocus();
                        } else if (freq.isNaN) {
                          freqFocusNode.requestFocus();
                        } else {
                          amountFocusNode.requestFocus();
                        }
                      }
                    },
                    child: const Text("Graph"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget buildCityInput(FocusNode focusNode) {
    return TextField(
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: 'City',
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      controller: controllerCity,
      onEditingComplete: () {
        setState(() {
          updateAndSaveData();
        });
      },
    );
  }

  Widget buildFreqInput(FocusNode focusNode) {
    return TextField(
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Frequency',
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      controller: controllerFreq,
      onEditingComplete: () {
        setState(() {
          updateAndSaveData();
        });
      },
    );
  }

  Widget buildAmountInput(FocusNode focusNode) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Amount',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            controller: controllerAmount,
            onEditingComplete: () {
              setState(() {
                updateAndSaveData();
              });
            },
          ),
        ),
        Column(
          children: [
            const Text("All"),
            Checkbox(
              value: all,
              onChanged: (newValue) {
                setState(() {
                  all = newValue!;
                  if (all) {
                    controllerAmount.clear();
                    amount = "";
                  }
                  updateAndSaveData();
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}


  // ниже пережитки прошлой версии дашборда

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
  // }

// class _MyGraphPage extends StatelessWidget {
//   final Random random = Random();
//
//   List<Map<String, dynamic>> generateRandomData() {
//     List<Map<String, dynamic>> data = [];
//     for (int i = 0; i < 6; i++) {
//       data.add({
//         'time': '2023-09-21 0$i:00:00',
//         'intensity': (random.nextInt(201) - 100).toDouble(),
//       });
//     }
//     return data;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<Map<String, dynamic>> data = generateRandomData();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Radio Wave Intensity'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: LineChart(
//           LineChartData(
//             gridData: const FlGridData(show: false),
//             titlesData: FlTitlesData(
//               leftTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   reservedSize: 30, // Adjust this value for label spacing
//                   interval: 20, // Adjust this value based on your intensity range
//                   getTitlesWidget: (value, meta) {
//                     return Text(value
//                         .toInt()
//                         .toString()); // Customize label format as needed
//                   },
//                 ),
//               ),
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     reservedSize: 30, // Adjust this value for label spacing
//                     interval: 1, // Adjust this value based on your data frequency
//                     getTitlesWidget: (value, meta) {
//                       // Convert value (index) to corresponding time from data
//                       if (value >= 0 && value < data.length) {
//                         final time = data[value.toInt()]["time"] as String;
//                         return Text(time.substring(
//                             11, 16)); // Display time in HH:mm format
//                       }
//                       return const Text('');
//                     },
//                   ),
//                 ),
//                 topTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false)), // Hide top titles
//                 rightTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false)), // Hide right titles
//               ),
//             borderData: FlBorderData(
//               show: true,
//               border: Border.all(color: const Color(0xff37434d), width: 1),
//             ),
//             minX: 0,
//             maxX: data.length.toDouble() - 1,
//             minY: -100,
//             maxY: 100,
//             // Adjust this based on your intensity data range
//             lineBarsData: [
//               LineChartBarData(
//                 spots: data.asMap().entries.map((entry) {
//                   final index = entry.key;
//                   final intensity = entry.value['intensity'] as double;
//                   return FlSpot(index.toDouble(), intensity);
//                 }).toList(),
//                 isCurved: true,
//                 color: Colors.blue,
//                 dotData: const FlDotData(show: false),
//                 belowBarData: BarAreaData(show: false),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class RequestScreen extends StatelessWidget {
//   final String url;
//   final double amplitude;
//   final int id;
//   final double frequency;
//
//   const RequestScreen(
//       {super.key,
//         required this.url,
//         required this.amplitude,
//         required this.id,
//         required this.frequency});
//
//   @override
//   Widget build(BuildContext context) {
//     final requestText = 'Requesting URL http://$url/$amplitude/$id/$frequency';
//
//     return Scaffold(
//         appBar: AppBar(
//           title: const Text('Request Details'),
//         ),
//         body: Center(
//           child: Text(requestText),
//         ));
//   }
// }