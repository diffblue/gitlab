export function removeTrialSuffix(planName) {
  return planName.replace(/ trial\b/i, '');
}
