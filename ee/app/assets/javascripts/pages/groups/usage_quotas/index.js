import $ from 'jquery';
import SeatUsageApp from 'ee/usage_quotas/seats';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
import initCiMinutesUsageApp from 'ee/usage_quotas/ci_minutes_usage';
import LinkedTabs from '~/lib/utils/bootstrap_linked_tabs';

const initLinkedTabs = () => {
  if (!document.querySelector('.js-storage-tabs')) {
    return false;
  }

  return new LinkedTabs({
    defaultAction: '#seats-quota-tab',
    parentEl: '.js-storage-tabs',
    hashedTabs: true,
  });
};

const initVueApps = () => {
  if (document.querySelector('#js-seat-usage-app')) {
    SeatUsageApp();
  }

  if (document.querySelector('#js-storage-counter-app')) {
    initNamespaceStorage();
  }

  initCiMinutesUsageApp();
};

/**
 * This adds the current URL hash to the pagingation links so that the page
 * opens in the correct tab. This happens because rails pagination doesn't add
 * URL hash, and it does a full page load, and then LinkedTabs looses track
 * of the opened page. Once we move pipelines to Vue, we won't need this hotfix.
 *
 * To be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/345373
 */
const fixPipelinesPagination = () => {
  const pipelinesQuotaTabLink = document.querySelector('#pipelines-quota');
  const pipelinesQuotaTab = document.querySelector('#pipelines-quota-tab');

  $(document).on('shown.bs.tab', (event) => {
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
initVueApps();
initLinkedTabs();
