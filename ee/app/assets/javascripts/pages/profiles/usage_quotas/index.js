import initCiMinutesUsageApp from 'ee/ci_minutes_usage';
import initPipelineUsageApp from 'ee/usage_quotas/pipelines';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
import LinkedTabs from '~/lib/utils/bootstrap_linked_tabs';
import { trackAddToCartUsageTab } from '~/google_tag_manager';

const initLinkedTabs = () => {
  if (!document.querySelector('.js-storage-tabs')) {
    return false;
  }
  return new LinkedTabs({
    defaultAction: '#pipelines-quota-tab',
    parentEl: '.js-storage-tabs',
    hashedTabs: true,
  });
};

initCiMinutesUsageApp();
initPipelineUsageApp();
initNamespaceStorage();
initLinkedTabs();
trackAddToCartUsageTab();
