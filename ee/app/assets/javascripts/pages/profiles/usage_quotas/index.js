import initPipelineUsageApp from 'ee/usage_quotas/pipelines';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
import { GlTabsBehavior, HISTORY_TYPE_HASH } from '~/tabs';
import { trackAddToCartUsageTab } from '~/google_tag_manager';

const initGlTabs = () => {
  const tabsEl = document.querySelector('.js-storage-tabs');
  if (!tabsEl) {
    return;
  }

  // eslint-disable-next-line no-new
  new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });
};

initPipelineUsageApp();
initNamespaceStorage();
initGlTabs();
trackAddToCartUsageTab();
