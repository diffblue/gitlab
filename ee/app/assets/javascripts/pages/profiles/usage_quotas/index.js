import ciMinutesUsage from 'ee/ci_minutes_usage';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
import LinkedTabs from '~/lib/utils/bootstrap_linked_tabs';
import { trackAddToCartUsageTab } from '~/google_tag_manager';

if (document.querySelector('#js-storage-counter-app')) {
  initNamespaceStorage();

  // eslint-disable-next-line no-new
  new LinkedTabs({
    defaultAction: '#pipelines-quota-tab',
    parentEl: '.js-storage-tabs',
    hashedTabs: true,
  });
}

ciMinutesUsage();
trackAddToCartUsageTab();
