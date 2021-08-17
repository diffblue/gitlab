import otherStorageCounter from 'ee/other_storage_counter';
import SeatUsageApp from 'ee/seat_usage';
import storageCounter from 'ee/storage_counter';
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
    storageCounter();
  }

  if (document.querySelector('#js-other-storage-counter-app')) {
    otherStorageCounter();
  }
};

initVueApps();
initLinkedTabs();
initSearchSettings();
