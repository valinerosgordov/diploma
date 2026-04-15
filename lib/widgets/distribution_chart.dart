import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/providers/file_analysis_provider.dart';

class DistributionChart extends StatelessWidget {
  const DistributionChart({super.key});

  @override
  Widget build(BuildContext context) {
    final distribution =
        context.select<FileAnalysisProvider, Map<String, double>>(
      (p) => p.fileDistribution,
    );

    if (distribution.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_rounded,
                    color: AppColors.primaryLight, size: 18),
                SizedBox(width: 8),
                Text(
                  'Distribution',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PieChart(
              dataMap: distribution,
              animationDuration: const Duration(milliseconds: 1000),
              chartLegendSpacing: 24,
              chartRadius: MediaQuery.of(context).size.width / 3.5,
              colorList: const [
                Color(0xFF6C5CE7),
                Color(0xFF00CEC9),
                Color(0xFFFDCB6E),
                Color(0xFFFF6B6B),
                Color(0xFF74B9FF),
                Color(0xFFA29BFE),
                Color(0xFF00B894),
                Color(0xFFE17055),
              ],
              initialAngleInDegree: 0,
              chartType: ChartType.ring,
              ringStrokeWidth: 24,
              legendOptions: const LegendOptions(
                showLegendsInRow: false,
                legendPosition: LegendPosition.right,
                showLegends: true,
                legendTextStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              chartValuesOptions: const ChartValuesOptions(
                showChartValueBackground: false,
                showChartValues: true,
                showChartValuesInPercentage: true,
                showChartValuesOutside: true,
                chartValueStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
