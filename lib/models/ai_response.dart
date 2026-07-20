
class Suggestion {

  final String title;
  final String description;

  Suggestion({
    required this.title,
    required this.description,
  });

}

class AIResponse {

  final String analysis;

  final List<Suggestion> suggestions;

  AIResponse({
    required this.analysis,
    required this.suggestions,
  });

}
