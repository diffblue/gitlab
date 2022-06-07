import $ from 'jquery';
import SeatUsageApp from 'ee/usage_quotas/seats';
import initPipelineUsageApp from 'ee/usage_quotas/pipelines';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
import initCiMinutesUsageApp from 'ee/usage_quotas/ci_minutes_usage';
import { GlTabsBehavior, TAB_SHOWN_EVENT } from '~/tabs';
import { trackAddToCartUsageTab } from '~/google_tag_manager';
import { historyReplaceState } from '~/lib/utils/common_utils';

/**
 * onTabChange and loadInitialTab are both set to be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/364037.
 *
 * These are workaround as part of refactoring LinkedTabs -> GlTabsBehavior.
 * Currently GlTabsBehavior doesn't support hash manipulation while LinkedTabs did out of the box.
 * To preserve the behavior during the refactor adding this logic here has been the path of least resistance.
 * Ideally GlTabsBehavior will handle this logic internally and will be implemented in the above mentioned issue.
 */
const onTabChange = (tabsEl) => {
  tabsEl.addEventListener(TAB_SHOWN_EVENT, (event) => {
    const tab = event.target;
    historyReplaceState(tab.getAttribute('href'));
  });
};

const loadInitialTab = (glTabs) => {
  const tab = glTabs.tabList.querySelector(`a[href="${window.location.hash}"]`);
  glTabs.activateTab(tab || glTabs.activeTab);
};

const initGlTabs = () => {
  const tabsEl = document.querySelector('.js-storage-tabs');
  if (!tabsEl) {
    return;
  }

  const glTabs = new GlTabsBehavior(tabsEl);
  onTabChange(tabsEl);
  loadInitialTab(glTabs);
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
