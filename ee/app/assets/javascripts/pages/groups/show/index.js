import '~/pages/groups/show';
import initGroupAnalytics from 'ee/analytics/group_analytics/group_analytics_bundle';
import { shouldQrtlyReconciliationMount } from 'ee/billings/qrtly_reconciliation';
import initVueAlerts from '~/vue_alerts';
import initTierBadgeTrigger from 'ee/groups/init_tier_badge_trigger';

initGroupAnalytics();
initVueAlerts();
shouldQrtlyReconciliationMount();
initTierBadgeTrigger();
