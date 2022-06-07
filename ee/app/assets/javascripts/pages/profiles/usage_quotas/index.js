import initCiMinutesUsageApp from 'ee/ci_minutes_usage';
import initPipelineUsageApp from 'ee/usage_quotas/pipelines';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
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

initCiMinutesUsageApp();
initPipelineUsageApp();
initNamespaceStorage();
initGlTabs();
trackAddToCartUsageTab();
