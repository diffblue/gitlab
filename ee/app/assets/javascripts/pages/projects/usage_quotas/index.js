import LinkedTabs from '~/lib/utils/bootstrap_linked_tabs';
import initProjectStorage from 'ee/usage_quotas/storage/init_project_storage';
import initSearchSettings from '~/search_settings';

const initLinkedTabs = () => {
  if (!document.querySelector('.js-usage-quota-tabs')) {
    return false;
  }

  return new LinkedTabs({
    defaultAction: '#storage-quota-tab',
    parentEl: '.js-usage-quota-tabs',
    hashedTabs: true,
  });
};

const initVueApp = () => {
  initProjectStorage('js-project-storage-count-app');
};

initVueApp();
initLinkedTabs();
initSearchSettings();
