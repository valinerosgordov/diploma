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
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: PieChart(
          dataMap: distribution,
          animationDuration: const Duration(milliseconds: 800),
          chartLegendSpacing: 32,
          chartRadius: MediaQuery.of(context).size.width / 3,
          colorList: const [
            Color(0xFFE94F4F),
            Color(0xFFFF6B6B),
            Color(0xFFFFA07A),
            Color(0xFF34D399),
            Color(0xFF60A5FA),
            Color(0xFFA78BFA),
          ],
          initialAngleInDegree: 0,
          chartType: ChartType.disc,
          legendOptions: const LegendOptions(
            showLegendsInRow: true,
            legendPosition: LegendPosition.bottom,
            showLegends: true,
            legendTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          chartValuesOptions: const ChartValuesOptions(
            showChartValueBackground: false,
            showChartValues: true,
            showChartValuesInPercentage: true,
            showChartValuesOutside: false,
            chartValueStyle: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
