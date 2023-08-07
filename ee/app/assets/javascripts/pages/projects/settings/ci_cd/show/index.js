import Vue from 'vue';
import { initGroupProtectedEnvironmentList } from 'ee/protected_environments/group_protected_environment_list';
import { initProtectedEnvironments } from 'ee/protected_environments/protected_environments';
import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';
import createStore from 'ee/vue_shared/license_compliance/store/index';
import '~/pages/projects/settings/ci_cd/show/index';

const el = document.getElementById('js-managed-licenses');

if (el?.dataset?.apiUrl) {
  const store = createStore();
  store.dispatch('licenseManagement/setIsAdmin', Boolean(el.dataset.apiUrl));
  store.dispatch('licenseManagement/setAPISettings', { apiUrlManageLicenses: el.dataset.apiUrl });
  // eslint-disable-next-line no-new
  new Vue({
    el,
    store,
    render(createElement) {
      return createElement(LicenseManagement, {
        props: {
          ...el.dataset,
        },
      });
    },
  });
}

initGroupProtectedEnvironmentList();
initProtectedEnvironments();
