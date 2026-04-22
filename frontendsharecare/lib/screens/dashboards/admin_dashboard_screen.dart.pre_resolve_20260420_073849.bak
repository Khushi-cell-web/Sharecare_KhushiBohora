import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_routes.dart';
import '../../core/services/sharecare_api_service.dart';
import '../../core/utils/network_error_helper.dart';
import '../../shared/providers/auth_provider.dart';

const _bg = Color(0xFF1e1e1e); // Darker gray for sidebar
const _mainBg = Color(0xFF161616); // Very dark gray for main content
const _cardBg = Color(0xFF1c1c1c); // Card background
const _textMain = Color(0xFFE0E0E0);
const _textLight = Color(0xFF808080);

const _accentBlue = Color(0xFF007bff);
const _accentRed = Color(0xFFdc3545);
const _accentGreen = Color(0xFF28a745);
const _accentYellow = Color(0xFFffc107);

const _sidebarHighlight = Color(0xFF2A2A2A);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ShareCareApiService _api = ShareCareApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.user?.role != 'admin') {
      setState(() {
        _loading = false;
        _error = 'Admin access required.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getAdminDashboard(auth.authHeaders);
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } on ShareCareApiException catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mainBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          _buildSidebar(context),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: _accentBlue,
                    backgroundColor: _cardBg,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _error!,
                                style: GoogleFonts.roboto(color: Colors.white),
                              ),
                            ),

                          // First Row: Sales Overview & Order Status
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 900;
                              if (isWide) {
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildSalesOverviewCard(),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 1,
                                      child: _buildOrderStatusCard(),
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _buildSalesOverviewCard(),
                                  const SizedBox(height: 24),
                                  _buildOrderStatusCard(),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Second Row: Donut Chart & Stat Cards
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 1100;
                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: _buildDonutChartCard(),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildSmallStatCard(
                                                  'Total Requests',
                                                  _data?['donation_requests_total']
                                                          ?.toString() ??
                                                      '8052',
                                                  '+25%',
                                                  _accentBlue,
                                                  Icons.shopping_cart_outlined,
                                                  true,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildSmallStatCard(
                                                  'Total Revenue',
                                                  '\$6.2K',
                                                  '+15%',
                                                  _accentRed,
                                                  Icons.attach_money_rounded,
                                                  false,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildSmallStatCard(
                                                  'New Users',
                                                  _data?['users_total']
                                                          ?.toString() ??
                                                      '1.3K',
                                                  '-10%',
                                                  _accentGreen,
                                                  Icons.people_outline_rounded,
                                                  true,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildSmallStatCard(
                                                  'Sold Items',
                                                  '956',
                                                  '-14%',
                                                  _accentYellow,
                                                  Icons.inventory_2_outlined,
                                                  false,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _buildDonutChartCard(),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSmallStatCard(
                                          'Total Requests',
                                          _data?['donation_requests_total']
                                                  ?.toString() ??
                                              '8052',
                                          '+25%',
                                          _accentBlue,
                                          Icons.shopping_cart_outlined,
                                          true,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildSmallStatCard(
                                          'Total Revenue',
                                          '\$6.2K',
                                          '+15%',
                                          _accentRed,
                                          Icons.attach_money_rounded,
                                          false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSmallStatCard(
                                          'New Users',
                                          _data?['users_total']?.toString() ??
                                              '1.3K',
                                          '-10%',
                                          _accentGreen,
                                          Icons.people_outline_rounded,
                                          true,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildSmallStatCard(
                                          'Sold Items',
                                          '956',
                                          '-14%',
                                          _accentYellow,
                                          Icons.inventory_2_outlined,
                                          false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          // Bottom row
                          _buildBottomRowCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Widgets -----

  Widget _buildSidebar(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final width = isWide ? 240.0 : 80.0;

    return Container(
      width: width,
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                if (isWide) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Rocker',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                if (isWide) _sidebarHeader('Dashboard'),
                _sidebarItem('Default', Icons.home_outlined, false, isWide),
                _sidebarItem('Alternate', Icons.adjust_rounded, true, isWide),
                _sidebarItem(
                  'Graphical',
                  Icons.leaderboard_outlined,
                  false,
                  isWide,
                ),
                if (isWide) _sidebarHeader('UI ELEMENTS'),
                _sidebarItem('Widgets', Icons.widgets_outlined, false, isWide),
                _sidebarItem(
                  'eCommerce',
                  Icons.shopping_bag_outlined,
                  false,
                  isWide,
                  hasAction: true,
                ),
                _sidebarItem(
                  'Components',
                  Icons.view_comfy_alt_outlined,
                  false,
                  isWide,
                  hasAction: true,
                ),
                _sidebarItem(
                  'Content',
                  Icons.note_add_outlined,
                  false,
                  isWide,
                  hasAction: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 8, right: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.roboto(
          color: _textLight.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _sidebarItem(
    String title,
    IconData icon,
    bool active,
    bool isWide, {
    bool hasAction = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: active ? _sidebarHighlight : Colors.transparent,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: active ? Colors.white : _textLight,
          size: 22,
        ),
        title: isWide
            ? Text(
                title,
                style: GoogleFonts.roboto(
                  color: active ? Colors.white : _textLight,
                  fontSize: 14,
                ),
              )
            : null,
        trailing: (isWide && hasAction)
            ? Icon(Icons.arrow_forward_ios_rounded, color: _textLight, size: 14)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
        ),
        contentPadding: EdgeInsets.only(left: isWide ? 24 : 0),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: _mainBg,
      child: Row(
        children: [
          Icon(Icons.menu_rounded, color: _textMain, size: 24),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: _textLight, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Search',
                    style: GoogleFonts.roboto(color: _textLight, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Actions
          Icon(Icons.language_rounded, color: _textLight, size: 22),
          const SizedBox(width: 16),
          Icon(Icons.light_mode_outlined, color: _textLight, size: 22),
          const SizedBox(width: 16),
          Icon(Icons.notifications_none_rounded, color: _textLight, size: 22),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundImage: const NetworkImage(
              'https://ui-avatars.com/api/?name=Admin&background=random',
            ),
          ),
        ],
      ),
    );
  }

  // --- Dashboard Cards ---

  Widget _buildSalesOverviewCard() {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Overview',
                style: GoogleFonts.roboto(
                  color: _textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: _textLight),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend('Donations', _accentYellow),
              const SizedBox(width: 24),
              _chartLegend('Requests', _accentBlue),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.roboto(
                                color: _textLight,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.roboto(
                          color: _textLight,
                          fontSize: 12,
                        ),
                      ),
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 10),
                      FlSpot(1, 20),
                      FlSpot(2, 12),
                      FlSpot(3, 10),
                      FlSpot(4, 16),
                      FlSpot(5, 7),
                      FlSpot(6, 14),
                    ],
                    isCurved: true,
                    color: _accentYellow,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _accentYellow.withOpacity(0.3),
                          _accentYellow.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 5),
                      FlSpot(1, 28),
                      FlSpot(2, 15),
                      FlSpot(3, 23),
                      FlSpot(4, 6),
                      FlSpot(5, 12),
                      FlSpot(6, 9),
                    ],
                    isCurved: true,
                    color: _accentBlue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _accentBlue.withOpacity(0.3),
                          _accentBlue.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard() {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Status',
                style: GoogleFonts.roboto(
                  color: _textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: _textLight),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 15,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, m) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.roboto(
                          color: _textLight,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        const months = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                        ];
                        if (v >= 0 && v < months.length)
                          return Text(
                            months[v.toInt()],
                            style: GoogleFonts.roboto(
                              color: _textLight,
                              fontSize: 12,
                            ),
                          );
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBarData(0, 9, _accentRed, _accentYellow),
                  _makeBarData(1, 7, _accentRed, _accentYellow),
                  _makeBarData(2, 14, _accentRed, _accentYellow),
                  _makeBarData(3, 10, _accentRed, _accentYellow),
                  _makeBarData(4, 12, _accentRed, _accentYellow),
                  _makeBarData(5, 8, _accentRed, _accentYellow),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarData(
    int x,
    double y,
    Color bottomColor,
    Color topColor,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 10,
          gradient: LinearGradient(
            colors: [bottomColor, topColor],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildDonutChartCard() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Center(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    color: _accentGreen,
                    value: 50,
                    title: '',
                    radius: 15,
                  ),
                  PieChartSectionData(
                    color: _accentRed,
                    value: 30,
                    title: '',
                    radius: 15,
                  ),
                  PieChartSectionData(
                    color: _accentBlue,
                    value: 20,
                    title: '',
                    radius: 15,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NGOs',
                  style: GoogleFonts.roboto(
                    color: _textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '30',
                  style: GoogleFonts.roboto(color: _textLight, fontSize: 14),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Text(
              'Hospitals',
              style: GoogleFonts.roboto(color: _textMain, fontSize: 12),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _accentRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '20',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(
    String title,
    String value,
    String percentage,
    Color color,
    IconData icon,
    bool useLineChart,
  ) {
    return Container(
      height: 117,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _sidebarHighlight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(color: _textLight, fontSize: 13),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.roboto(
                  color: _textMain,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                percentage,
                style: GoogleFonts.roboto(
                  color: percentage.startsWith('+') ? _accentGreen : _accentRed,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 20,
            child: useLineChart
                ? CustomPaint(
                    painter: _MiniSparklinePainter(color: color),
                    child: Container(),
                  )
                : CustomPaint(
                    painter: _MiniBarChartPainter(color: color),
                    child: Container(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRowCard() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Visits',
                style: GoogleFonts.roboto(color: _textLight, fontSize: 13),
              ),
              Text(
                '12M',
                style: GoogleFonts.roboto(
                  color: _textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(Icons.videocam_outlined, color: _accentBlue, size: 30),
        ],
      ),
    );
  }

  Widget _chartLegend(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.roboto(color: _textLight, fontSize: 12)),
      ],
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final Color color;
  _MiniSparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.2, size.height * 0.8);
    path.lineTo(size.width * 0.4, size.height * 0.2);
    path.lineTo(size.width * 0.6, size.height * 0.6);
    path.lineTo(size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width, size.height * 0.4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniBarChartPainter extends CustomPainter {
  final Color color;
  _MiniBarChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 25;
    for (int i = 0; i < 15; i++) {
      double h = (i % 3 == 0)
          ? size.height * 0.8
          : (i % 2 == 0)
          ? size.height * 0.4
          : size.height * 0.6;
      canvas.drawRect(
        Rect.fromLTWH(i * (barWidth * 1.5), size.height - h, barWidth, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
