class Movie {
  String name;
  Movie({required this.name});

  factory Movie.fromJson(Map<String, dynamic> str) => Movie(name: str['name']);
}
