import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class CareerScreen extends StatefulWidget {
  @override
  _CareerScreenState createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
  List<Map<String, dynamic>> _jobListings = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _locationFilter = 'India';
  String _jobTypeFilter = 'fulltime,parttime,intern,contractor';

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final query = _searchController.text.isNotEmpty 
        ? Uri.encodeComponent(_searchController.text)
        : 'Developer';
    
    final url = Uri.parse(
      'https://jobs-api14.p.rapidapi.com/v2/list?'
      'query=$query&'
      'location=${Uri.encodeComponent(_locationFilter)}&'
      'autoTranslateLocation=true&'
      'remoteOnly=false&'
      'employmentTypes=$_jobTypeFilter'
    );

    final headers = {
      'X-RapidAPI-Key': '68c38f446emshe123d5f890926adp191018jsndf152c62a366',
      'X-RapidAPI-Host': 'jobs-api14.p.rapidapi.com',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('jobs')) {
          final jobsData = jsonResponse['jobs'];

          if (jobsData is List) {
            setState(() {
              _jobListings = jobsData.map((job) {
                // Collect all available apply URLs
                List<String> applyUrls = [];
                if (job['jobProviders'] != null && job['jobProviders'] is List) {
                  for (var provider in job['jobProviders']) {
                    if (provider['url'] != null && provider['url'].toString().isNotEmpty) {
                      applyUrls.add(provider['url']);
                    }
                  }
                }

                return {
                  'id': job['id'] ?? '',
                  'title': job['title'] ?? 'No Title',
                  'company': job['company'] ?? 'Unknown Company',
                  'location': job['location'] ?? 'Location Not Specified',
                  'type': job['employmentType'] ?? 'Not Specified',
                  'posted': job['datePosted'] ?? 'Unknown',
                  'description': job['description'] ?? 'No description available',
                  'salary': job['salaryRange']?.toString() ?? 'Not disclosed',
                  'applyUrls': applyUrls,
                  'logo': _getCompanyLogo(job['company'] ?? ''),
                };
              }).where((job) => job['title'] != 'No Title').toList();
            });
          } else {
            setState(() => _errorMessage = "Jobs data is not in expected format");
          }
        } else {
          setState(() => _errorMessage = "Response missing 'jobs' key");
        }
      } else {
        setState(() => _errorMessage = "Failed to load jobs: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error fetching jobs: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getCompanyLogo(String company) {
    if (company.contains('Hospital') || company.contains('Medical')) return '🏥';
    if (company.contains('Tech') || company.contains('Software')) return '💻';
    if (company.contains('School') || company.contains('Education')) return '🏫';
    if (company.contains('Restaurant') || company.contains('Food')) return '🍴';
    return '🏢';
  }

  Future<void> _launchJobUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link - URL copied to clipboard'),
              action: SnackBarAction(
                label: 'Try Again',
                onPressed: () => _launchJobUrl(url),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Listings'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchJobs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: fetchJobs,
                  child: Text('Search'),
                ),
              ],
            ),
          ),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _jobListings.isEmpty
                        ? Center(child: Text("No jobs found"))
                        : ListView.builder(
                            padding: EdgeInsets.all(8),
                            itemCount: _jobListings.length,
                            itemBuilder: (context, index) {
                              final job = _jobListings[index];
                              return JobCard(
                                job: job,
                                onApply: (url) => _launchJobUrl(url),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: Text('All Types'),
            selected: _jobTypeFilter == 'fulltime,parttime,intern,contractor',
            onSelected: (selected) {
              setState(() {
                _jobTypeFilter = 'fulltime,parttime,intern,contractor';
              });
              fetchJobs();
            },
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Full-time'),
            selected: _jobTypeFilter == 'fulltime',
            onSelected: (selected) {
              setState(() {
                _jobTypeFilter = 'fulltime';
              });
              fetchJobs();
            },
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Remote'),
            selected: _locationFilter == 'Remote',
            onSelected: (selected) {
              setState(() {
                _locationFilter = 'Remote';
              });
              fetchJobs();
            },
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('USA'),
            selected: _locationFilter == 'United States',
            onSelected: (selected) {
              setState(() {
                _locationFilter = 'United States';
              });
              fetchJobs();
            },
          ),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final Function(String) onApply;

  const JobCard({
    required this.job,
    required this.onApply,
  });

  void _showApplyOptions(BuildContext context) {
    if (job['applyUrls'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No application links available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply through:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ...job['applyUrls'].map<Widget>((url) {
                final domain = Uri.parse(url).host.replaceAll('www.', '');
                return ListTile(
                  leading: Icon(Icons.open_in_new),
                  title: Text(domain),
                  onTap: () {
                    Navigator.pop(context);
                    onApply(url);
                  },
                );
              }).toList(),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      elevation: 3,
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
                      SizedBox(height: 4),
                      Text(
                        job['company'],
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(job['location']),
                Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(job['posted']),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.work, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(job['type']),
                Spacer(),
                Icon(Icons.attach_money, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(job['salary']),
              ],
            ),
            SizedBox(height: 12),
            Text(
              job['description'],
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  if (job['applyUrls'].length == 1) {
                    onApply(job['applyUrls'][0]);
                  } else {
                    _showApplyOptions(context);
                  }
                },
                child: Text(
                  job['applyUrls'].isEmpty 
                      ? 'No Apply Link' 
                      : job['applyUrls'].length == 1 
                          ? 'Apply Now' 
                          : 'View Apply Options (${job['applyUrls'].length})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}