import 'dart:async';
import 'dart:convert';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;

Future<dotaMatch> fetchMatch() async {
  final response = await http
      .get(Uri.parse('https://api.opendota.com/api/matches/6991931201'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return dotaMatch.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class dotaMatch {
  final int matchId;
  final int direScore;
  final int radiantScore;

  const dotaMatch({
    required this.matchId,
    required this.direScore,
    required this.radiantScore,
  });

  factory dotaMatch.fromJson(Map<String, dynamic> json) {
    return dotaMatch(
      matchId: json['match_id'],
      direScore: json['dire_score'],
      radiantScore: json['radiant_score'],
    );
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
  late Future<dotaMatch> futureMatch;

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
          title: const Text('Dota Match'),
        ),
        body: Center(
          child: FutureBuilder<dotaMatch>(
            future: futureMatch,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data!.matchId.toString());
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
