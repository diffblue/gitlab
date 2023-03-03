import initUsageQuotas from '~/usage_quotas';
import SeatUsageApp from 'ee/usage_quotas/seats';
import initPipelineUsageApp from 'ee/usage_quotas/pipelines';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
import { GlTabsBehavior, HISTORY_TYPE_HASH } from '~/tabs';
import { trackAddToCartUsageTab } from '~/google_tag_manager';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';

const initGlTabs = () => {
  const tabsEl = document.querySelector('.js-storage-tabs');
  if (!tabsEl) {
    return;
  }

  // eslint-disable-next-line no-new
  new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });
};

const legacyInitUsageQuotas = () => {
  SeatUsageApp();
  initPipelineUsageApp();
  initNamespaceStorage();
  initGlTabs();
  trackAddToCartUsageTab();

  if (window.gon.features?.dataTransferMonitoring) {
    import('ee/usage_quotas/transfer')
      .then(({ initGroupTransferApp }) => {
        initGroupTransferApp();
      })
      .catch(() => {
        createAlert({
          message: s__(
            'UsageQuotas|An error occurred loading the transfer data. Please refresh the page to try again.',
          ),
        });
      });
  }
};

if (gon.features?.usageQuotasForAllEditions) {
  initUsageQuotas();
} else {
  legacyInitUsageQuotas();
}
