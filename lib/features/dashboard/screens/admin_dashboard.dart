import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/models/alert.dart';
import '../widgets/stats_card.dart';
import '../widgets/recent_activity.dart';
import '../widgets/alert_list.dart';
import '../providers/dashboard_provider.dart';
import '../../settings/providers/settings_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Warehouse? _selectedWarehouse;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Load data when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      // Load available warehouses
      await settingsProvider.loadWarehouses();

      // If there are warehouses, select the first one by default
      if (settingsProvider.warehouses.isNotEmpty &&
          _selectedWarehouse == null) {
        _selectedWarehouse = settingsProvider.warehouses.first;
      }

      // Load dashboard data for selected warehouse and date range
      if (_selectedWarehouse != null) {
        await dashboardProvider.loadDashboardData(
          warehouseId: _selectedWarehouse!.id,
          fromDate: _dateRange.start,
          toDate: _dateRange.end,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warehouse selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Warehouse',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Warehouse>(
                              value: _selectedWarehouse,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              items:
                                  settingsProvider.warehouses.map((warehouse) {
                                return DropdownMenuItem<Warehouse>(
                                  value: warehouse,
                                  child: Text(warehouse.name),
                                );
                              }).toList(),
                              onChanged: (warehouse) {
                                setState(() {
                                  _selectedWarehouse = warehouse;
                                });
                                _loadDashboardData();
                              },
                            ),
                            const SizedBox(height: 16),
                            Text('Date Range',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      '${_dateRange.start.day}/${_dateRange.start.month} - ${_dateRange.end.day}/${_dateRange.end.month}',
                                    ),
                                    onPressed: () async {
                                      final result = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime.now().subtract(
                                            const Duration(days: 365)),
                                        lastDate: DateTime.now(),
                                        initialDateRange: _dateRange,
                                      );

                                      if (result != null) {
                                        setState(() {
                                          _dateRange = result;
                                        });
                                        _loadDashboardData();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats summary
                    Text('Overview',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),

                    // Adjust Grid for Responsiveness
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2; // Default to 2 columns
                        if (constraints.maxWidth > 600) {
                          crossAxisCount = 4; // Larger screens
                        }
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.5,
                          children: [
                            StatsCard(
                              title: 'Total Access',
                              value: dashboardProvider.totalAccess.toString(),
                              icon: Icons.door_sliding,
                              color: Colors.blue,
                            ),
                            StatsCard(
                              title: 'Inspections',
                              value:
                                  dashboardProvider.totalInspections.toString(),
                              icon: Icons.checklist,
                              color: Colors.green,
                            ),
                            StatsCard(
                              title: 'Alerts',
                              value: dashboardProvider.totalAlerts.toString(),
                              icon: Icons.warning,
                              color: Colors.orange,
                            ),
                            StatsCard(
                              title: 'Issue Rate',
                              value:
                                  '${dashboardProvider.issueRate.toStringAsFixed(1)}%',
                              icon: Icons.report_problem,
                              color: Colors.red,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Recent Activity
                    Text('Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    RecentActivity(
                        activities: dashboardProvider.recentActivities),

                    const SizedBox(height: 24),

                    // Active Alerts
                    if (dashboardProvider.activeAlerts.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Alerts',
                              style: Theme.of(context).textTheme.titleLarge),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/alerts'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AlertList(alerts: dashboardProvider.activeAlerts),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show menu with quick actions
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New Access'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/access/new');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Scan QR Code'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/access/scan');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_task),
                  title: const Text('New Inspection'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/inspection/new');
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
