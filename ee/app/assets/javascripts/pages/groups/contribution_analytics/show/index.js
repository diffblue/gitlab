import initContributionAnalytics from 'ee/analytics/contribution_analytics';

const el = document.getElementById('js-contribution-analytics');
if (el) {
  initContributionAnalytics(el);
}
