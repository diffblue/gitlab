import initContributionAnalytics from 'ee/analytics/contribution_analytics';
import initGroupMemberContributions from 'ee/group_member_contributions';

const el = document.getElementById('js-contribution-analytics');
if (el) {
  initContributionAnalytics(el);
  initGroupMemberContributions();
}
