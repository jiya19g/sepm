import 'package:flutter/material.dart';

class CareerScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _jobListings = [
    {
      'title': 'Software Engineer Intern',
      'company': 'Tech Innovations Inc.',
      'location': 'San Francisco, CA',
      'type': 'Internship',
      'posted': '2 days ago',
      'logo': '🧑‍💻',
    },
    {
      'title': 'Data Analyst',
      'company': 'Global Insights',
      'location': 'Remote',
      'type': 'Full-time',
      'posted': '1 week ago',
      'logo': '📊',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Listings'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _jobListings.length,
        itemBuilder: (context, index) {
          final job = _jobListings[index];
          return JobCard(job: job);
        },
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(job['logo']),
                  backgroundColor: Colors.grey[200],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        job['company'],
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(job['location']),
                Spacer(),
                Icon(Icons.work_outline, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(job['type']),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  job['posted'],
                  style: TextStyle(color: Colors.grey),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}