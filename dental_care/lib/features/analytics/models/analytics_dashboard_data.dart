class AnalyticsSummaryCard {
  final String label;
  final String value;
  final double delta;

  const AnalyticsSummaryCard({
    required this.label,
    required this.value,
    required this.delta,
  });
}

class TrendPoint {
  final String label;
  final double value;

  const TrendPoint({
    required this.label,
    required this.value,
  });
}

class PieSliceData {
  final String label;
  final double value;

  const PieSliceData({
    required this.label,
    required this.value,
  });
}

class RadarMetric {
  final String label;
  final double score;

  const RadarMetric({
    required this.label,
    required this.score,
  });
}

class BarMetric {
  final String label;
  final double value;

  const BarMetric({
    required this.label,
    required this.value,
  });
}

class AnalyticsDashboardData {
  final List<AnalyticsSummaryCard> summary;
  final List<TrendPoint> weeklyTrend;
  final List<PieSliceData> questionDistribution;
  final List<RadarMetric> difficultyDistribution;
  final List<BarMetric> completionByCohort;

  const AnalyticsDashboardData({
    required this.summary,
    required this.weeklyTrend,
    required this.questionDistribution,
    required this.difficultyDistribution,
    required this.completionByCohort,
  });
}
