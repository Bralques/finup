import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/analysis_repository.dart';

final analysisRepositoryProvider = Provider<AnalysisRepository>(
  (ref) => AnalysisRepository(),
);

final analysisProvider = AsyncNotifierProvider<AnalysisNotifier, FinancialAnalysis?>(
  AnalysisNotifier.new,
);

class AnalysisNotifier extends AsyncNotifier<FinancialAnalysis?> {
  @override
  Future<FinancialAnalysis?> build() async => null;

  Future<void> analyze() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(analysisRepositoryProvider).analyze(),
    );
  }
}
