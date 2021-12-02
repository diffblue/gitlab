import SeatUsageApp from 'ee/seat_usage';
import initNamespaceStorage from 'ee/usage_quotas/storage/init_namespace_storage';
import LinkedTabs from '~/lib/utils/bootstrap_linked_tabs';
import initSearchSettings from '~/search_settings';

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
};

initVueApps();
initLinkedTabs();
initSearchSettings();
