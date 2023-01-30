import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'movie.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Movie> _temp = [];
  List<Movie> _movies = [];

  DocumentSnapshot? _lastDocument;

  bool _gettingMoreMovies = false;
  bool _moreMoviesAvailable = true;

  bool _loadingMovies = true;
  int _per_page = 10;

  ScrollController _scrollController = ScrollController();

  _getMovies() async {
    setState(() {
      _loadingMovies = true;
    });

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('movies')
        .orderBy('name')
        .limit(_per_page)
        .get();

    _movies = querySnapshot.docs.map((e) {
      return Movie.fromJson(e.data() as Map<String, dynamic>);
    }).toList();

    if (_movies.length < _per_page) {
      _moreMoviesAvailable = false;
    }
    _lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];
    setState(() {
      _loadingMovies = false;
    });
  }

  _getMoreMovies() async {
    print('********** Get More Movies');

    if (_moreMoviesAvailable == false) {
      return;
    }

    if (_gettingMoreMovies == true) {
      return;
    }

    _gettingMoreMovies = true;
    print('Value ------ ${_lastDocument!.data().toString()}');

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('movies')
        .orderBy('name')
        .startAfter([(_lastDocument!.data() as Map<String, dynamic>)['name']])
        .limit(_per_page)
        .get();

    _temp.clear();
    _temp = querySnapshot.docs.map((e) {
      print('Load More ${e.data()}');
      return Movie.fromJson(e.data() as Map<String, dynamic>);
    }).toList();

    if (_temp.length < _per_page) {
      _moreMoviesAvailable = false;
    }

    print('Temp Size ${_temp.length}');

    _lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];

    _movies.addAll(_temp);

    setState(() {});

    _gettingMoreMovies = false;
  }

  @override
  void initState() {
    _getMovies();
    _scrollController.addListener(() {
      double maxScroll = _scrollController!.position.maxScrollExtent;
      double currentScroll = _scrollController!.position.pixels;
      double delta = MediaQuery.of(context).size.width * 0.25;

      if (maxScroll - currentScroll <= delta) {
        _getMoreMovies();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firestore Pagination'),
      ),
      body: _loadingMovies == true
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              child: _movies.length == 0
                  ? Center(
                      child: Text('No Movies Found'),
                    )
                  : ListView.separated(
                      separatorBuilder: (context, index) {
                        return Divider();
                      },
                      controller: _scrollController,
                      itemCount: _movies.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(_movies[index].name),
                        );
                      },
                    ),
            ),
    );
  }
}
