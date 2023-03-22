import { extractVSAFeaturesFromGON } from '~/analytics/shared/utils';
import initFOSSCycleAnalytics from '~/analytics/cycle_analytics';
import initCycleAnalytics from 'ee/analytics/cycle_analytics';

export default () => {
  const { cycleAnalyticsForProjects, vsaGroupAndProjectParity } = extractVSAFeaturesFromGON();
  const hasCycleAnalyticsForProjects = vsaGroupAndProjectParity && cycleAnalyticsForProjects;

  if (hasCycleAnalyticsForProjects) {
    initCycleAnalytics();
  } else {
    initFOSSCycleAnalytics();
  }
};
