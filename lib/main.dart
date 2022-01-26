import 'dart:async';
import 'dart:convert';

import 'package:battery/battery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_wake/flutter_screen_wake.dart';
import 'package:get_values/theme_model.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

void main() {
  runApp( MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HomeScreen();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final resultNotifier = ValueNotifier<RequestState>(RequestInitial());

  var data;
  // late String bp ='';
  late double bri = 1.0;

  Future<void> makeGetRequest() async {
    resultNotifier.value = RequestLoadInProgress();
    final url = Uri.parse('http://k.j/s/1/');
    Response response = await get(url);

    data = jsonDecode(response.body);
    print(data);
    setState(() {
      // bp= data["batterypercentage"].toString();
      bri = data["brightness"];
      FlutterScreenWake.setBrightness(bri);
    });
    _handleResponse(response);
  }

  void _handleResponse(Response response) {
    if (response.statusCode >= 400) {
      resultNotifier.value = RequestLoadFailure();
    } else {
      resultNotifier.value = RequestLoadSuccess(response.body);
    }
  }

  Future<void> makePutRequest() async {
    resultNotifier.value = RequestLoadInProgress();
    final url = Uri.parse('http://k.j/s/1/');
    final headers = {"Content-type": "application/json"};
    final json = '{"batterypercentage": $batteryLevel}';
    final response = await put(url, headers: headers, body: json);
    // print('Status code: ${response.statusCode}');
    // print('Body: ${response.body}');
  }

  final battery = Battery();
  int batteryLevel = 100;

  BatteryState batteryState = BatteryState.full;

  late Timer timer;
  late StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    listenBatteryLevel();
    listenBatteryState();
    // initPlatformBrightness();
    // getBrightness();
    Timer.periodic(Duration(microseconds: 200), (timer)  => makeGetRequest());
    Timer.periodic(Duration(seconds: 1), (timer)  => makePutRequest());

  }

  void listenBatteryState() =>
      subscription = battery.onBatteryStateChanged.listen(
            (batteryState) => setState(() => this.batteryState = batteryState),
      );

  void listenBatteryLevel() {
    updateBatteryLevel();
    timer = Timer.periodic(const Duration(seconds: 5),
          (_) async =>updateBatteryLevel(),
    );
  }

  Future updateBatteryLevel() async {
    final batteryLevel = await battery.batteryLevel;
    setState(() =>this.batteryLevel = batteryLevel);
  }

  @override
  void dispose() {
    timer.cancel();
    subscription.cancel();
    super.dispose();
  }

  double brightness = 0.0;
  bool toggle = false;



  void getBrightness() async {
    double value = await brightness;
    setState(() {
      brightness = double.parse(value.toStringAsFixed(1));
    });
  }


  bool _light = true;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeModel(),
      child: Consumer(
        builder: (context, ThemeModel themeNotifier, child){
          return MaterialApp(
            theme: themeNotifier.isDark? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
              appBar: AppBar(
                title: const Text(
                    'Tab'
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                      onPressed: () {
                        themeNotifier.isDark
                            ? themeNotifier.isDark = false
                            :themeNotifier.isDark = true;
                      }, icon: Icon(
                    themeNotifier.isDark
                        ?Icons.wb_sunny : Icons.nightlight_round
                  ),
                  ),
                ],
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildBatteryLevel(batteryLevel),
                    buildBatteryState(batteryState),
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        border: Border.all(
                          color: Colors.blue,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            spreadRadius: 2,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              AnimatedCrossFade(
                                firstChild: const Icon(Icons.brightness_7,size:50,color: Colors.blue,),
                                secondChild: const Icon(Icons.brightness_3,size:50,color: Colors.blue  ,),
                                crossFadeState: toggle ? CrossFadeState.showSecond: CrossFadeState.showFirst,
                                duration: const Duration(seconds: 1),
                              ),
                              Expanded(
                                child: Slider(
                                  value: bri,
                                  onChanged: (value) {
                                    setState(() {
                                      bri = value;
                                      FlutterScreenWake.setBrightness(bri);
                                    });

                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                            "${bri.toStringAsFixed(1)}" + "%",
                            style: const TextStyle
                              (color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),




                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
    }
    )
    );

  }



  Widget buildBatteryState(BatteryState batteryState) {
    final style = TextStyle(fontSize: 32,color: Colors.blue);
    final double size = 100;

    switch (batteryState) {
      case BatteryState.full:
        final color = Colors.green;
        return Column(
          children: [
            Icon(Icons.battery_full, size: size, color:color),
            Text('Full', style: style.copyWith(color: color)),
          ],
        );

      case BatteryState.charging:
        final color = Colors.green;
        return Column(
          children: [
            Icon(Icons.battery_charging_full_rounded, size: size, color:color,),
            Text('Charging...', style: style.copyWith(color: color)),
          ],
        );

      case BatteryState.discharging:
      default:
        final color = Colors.red;
        return Column(
          children: [
            Icon(Icons.battery_alert, size: size, color:color,),
            Text('Discharging', style: style.copyWith(color: color)),
          ],

        );
    }
  }


  Widget buildBatteryLevel(int batteryLevel) => Text(
    '$batteryLevel%',
    style: const TextStyle(
      fontSize: 46,
      color: Colors.blue,
      fontWeight: FontWeight.bold,
    ),
  );
}



class RequestState {
  const RequestState();
}

class RequestInitial extends RequestState {}

class RequestLoadInProgress extends RequestState {}

class RequestLoadSuccess extends RequestState {
  const RequestLoadSuccess(this.body);
  final String body;
}

class RequestLoadFailure extends RequestState {}





