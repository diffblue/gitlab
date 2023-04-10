import initUsageQuotas from '~/usage_quotas';
import initSeatUsageApp from 'ee/usage_quotas/seats';
import initPipelineUsageApp from 'ee/usage_quotas/pipelines';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
import { GlTabsBehavior, HISTORY_TYPE_HASH, TAB_SHOWN_EVENT } from '~/tabs';
import { trackAddToCartUsageTab } from '~/google_tag_manager';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

const legacyInitUsageQuotas = () => {
  const tabsEl = document.querySelector('.js-storage-tabs');
  if (!tabsEl) {
    return;
  }

  const initializers = {
    'seats-quota-tab': {
      wasInited: false,
      init: initSeatUsageApp,
    },
    'pipelines-quota-tab': {
      wasInited: false,
      init: initPipelineUsageApp,
    },
    'storage-quota-tab': {
      wasInited: false,
      init: initNamespaceStorage,
    },
  };

  tabsEl.addEventListener(TAB_SHOWN_EVENT, (event) => {
    /** @type HTMLElement */
    const el = event.detail?.activeTabPanel;
    const initializer = initializers[el.id];
    if (!initializer || initializer.wasInited) {
      return;
    }

    initializer.init();
    initializer.wasInited = true;
  });

  // eslint-disable-next-line no-new
  new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });

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
