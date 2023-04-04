import Vue from 'vue';
import Vuex from 'vuex';
import LicenseReportApp from 'ee/vue_shared/license_compliance/mr_widget_license_report.vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import { updateBadgeCount } from './utils';

Vue.use(Translate);
Vue.use(Vuex);

export default () => {
  const licensesTab = document.getElementById('js-licenses-app');

  if (licensesTab) {
    const {
      canManageLicenses,
      apiUrl,
      licensesApiPath,
      securityPoliciesPath,
    } = licensesTab.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el: licensesTab,
      components: {
        LicenseReportApp,
      },
      store: new Vuex.Store(),
      render(createElement) {
        return createElement('license-report-app', {
          props: {
            apiUrl,
            licensesApiPath,
            securityPoliciesPath,
            canManageLicenses: parseBoolean(canManageLicenses),
            alwaysOpen: true,
            reportSectionClass: 'split-report-section',
          },
          on: {
            updateBadgeCount: (count) => {
              updateBadgeCount('.js-licenses-counter', count);
            },
          },
        });
      },
    });
  }
};
