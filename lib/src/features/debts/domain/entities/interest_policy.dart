class InterestPolicy {
  const InterestPolicy({
    required this.monthlyRate,
    required this.generationCycleDays,
    required this.appliesOnOverdueOnly,
    required this.compoundInterest,
  });

  final double monthlyRate;
  final int generationCycleDays;
  final bool appliesOnOverdueOnly;
  final bool compoundInterest;
}
