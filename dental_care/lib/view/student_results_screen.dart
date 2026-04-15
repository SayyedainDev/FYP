import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/quiz_provider.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({Key? key}) : super(key: key);

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with tabs
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Quiz Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade700, Colors.blue.shade900],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  icon: Icon(Icons.history),
                  text: 'All Attempts',
                ),
                Tab(
                  icon: Icon(Icons.bar_chart),
                  text: 'Statistics',
                ),
              ],
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: All Attempts
                _buildAttemptsTab(),

                // Tab 2: Statistics
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsTab() {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        // In a real app, you'd fetch student attempts from the provider
        // For now, we'll show a message about loading attempts
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter/Sort controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Quiz Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (value) {
                        setState(() => _sortBy = value);
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'date',
                          child: Text('Sort by Date'),
                        ),
                        const PopupMenuItem(
                          value: 'score',
                          child: Text('Sort by Score'),
                        ),
                        const PopupMenuItem(
                          value: 'title',
                          child: Text('Sort by Quiz'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sort, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              'Sort',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Empty state with instructions
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No quiz attempts yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Take a quiz to see your results here',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go to Quizzes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Quizzes',
                    value: '0',
                    icon: Icons.quiz,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Passed',
                    value: '0',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Average Score',
                    value: '0%',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Best Score',
                    value: '0%',
                    icon: Icons.star,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Performance Insight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Insight',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Take your first quiz to see performance analysis and detailed insights about your learning progress.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
