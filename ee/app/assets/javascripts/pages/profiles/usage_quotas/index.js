import ciMinutesUsage from 'ee/ci_minutes_usage';
import otherStorageCounter from 'ee/other_storage_counter';
import storageCounter from 'ee/storage_counter';
import LinkedTabs from '~/lib/utils/bootstrap_linked_tabs';

if (document.querySelector('#js-storage-counter-app')) {
  storageCounter();

  // eslint-disable-next-line no-new
  new LinkedTabs({
    defaultAction: '#pipelines-quota-tab',
    parentEl: '.js-storage-tabs',
    hashedTabs: true,
  });
}

if (document.querySelector('#js-other-storage-counter-app')) {
  otherStorageCounter();

  // eslint-disable-next-line no-new
  new LinkedTabs({
    defaultAction: '#pipelines-quota-tab',
    parentEl: '.js-other-storage-tabs',
    hashedTabs: true,
  });
}

ciMinutesUsage();
