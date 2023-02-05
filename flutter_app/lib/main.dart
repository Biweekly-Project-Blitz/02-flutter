import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

Future<recentMatches> fetchMatch() async {
  final response = await http.get(
      Uri.parse('https://api.opendota.com/api/players/41742204/recentMatches'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    print('An HTTP request was made');
    print(recentMatches.fromJson(jsonDecode(response.body)));
    return recentMatches.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class recentMatches {
  final List match;

  const recentMatches({required this.match});

  factory recentMatches.fromJson(json) {
    return recentMatches(match: json);
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<recentMatches> futureMatch;

  void getItems() {
    futureMatch = fetchMatch();
  }

  @override
  void initState() {
    super.initState();
    futureMatch = fetchMatch();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dota Match Fetcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dota Matches'),
        ),
        body: Center(
          child: FutureBuilder<recentMatches>(
            future: futureMatch,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Scaffold(
                    body: Column(
                  children: [
                    Text("Matches:"),
                    SizedBox(
                      height: 600, // fixed height
                      child: ListView(
                        children: <Widget>[
                          for (var item in snapshot.data!.match)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                // ↓ Change this line.
                                child: Text(item['match_id'].toString()),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          getItems();
                        },
                        child: Text('Refresh Recent Matches'))
                  ],
                ));
                //return Text(snapshot.data!.matchId.toString());
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
