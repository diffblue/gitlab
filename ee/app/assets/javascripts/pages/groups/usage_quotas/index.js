import $ from 'jquery';
import SeatUsageApp from 'ee/usage_quotas/seats';
import initPipelineUsageApp from 'ee/ci/usage_quotas/pipelines';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
import initCiMinutesUsageApp from 'ee/ci/usage_quotas/ci_minutes_usage';
import { GlTabsBehavior, TAB_SHOWN_EVENT, HISTORY_TYPE_HASH } from '~/tabs';
import { trackAddToCartUsageTab } from '~/google_tag_manager';

const initGlTabs = () => {
  const tabsEl = document.querySelector('.js-storage-tabs');
  if (!tabsEl) {
    return;
  }

  // eslint-disable-next-line no-new
  new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });
};

/**
 * This adds the current URL hash to the pagination links so that the page
 * opens in the correct tab. This happens because rails pagination doesn't add
 * URL hash, and it does a full page load, and then LinkedTabs looses track
 * of the opened page. Once we move pipelines to Vue, we won't need this hotfix.
 *
 * To be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/345373
 */
const fixPipelinesPagination = () => {
  if (gon.features?.usageQuotasPipelinesVue) {
    return;
  }

  const pipelinesQuotaTabLink = document.querySelector("a[href='#pipelines-quota-tab']");
  const pipelinesQuotaTab = document.querySelector('#pipelines-quota-tab');

  $(document).on(TAB_SHOWN_EVENT, (event) => {
    if (event.target.id === pipelinesQuotaTabLink.id) {
      const pageLinks = pipelinesQuotaTab.querySelectorAll('.page-link');

      Array.from(pageLinks).forEach((pageLink) => {
        // eslint-disable-next-line no-param-reassign
        pageLink.href = pageLink.href.split('#')[0].concat(window.location.hash);
      });
    }
  });
};

fixPipelinesPagination();
SeatUsageApp();
initPipelineUsageApp();
initNamespaceStorage();
initCiMinutesUsageApp();
initGlTabs();
trackAddToCartUsageTab();
