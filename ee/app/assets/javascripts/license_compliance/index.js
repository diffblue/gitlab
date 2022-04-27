import Vue from 'vue';
import LicenseComplianceApp from './components/app.vue';
import createStore from './store';
import { LICENSE_LIST } from './store/constants';

export default () => {
  const el = document.querySelector('#js-licenses-app');
  const {
    projectLicensesEndpoint,
    readLicensePoliciesEndpoint,
    writeLicensePoliciesEndpoint,
    projectId,
    projectPath,
    rulesPath,
    settingsPath,
    approvalsDocumentationPath,
    lockedApprovalsRuleName,
    softwareLicenses,
  } = el.dataset;

  const storeSettings = {
    projectId,
    projectPath,
    rulesPath,
    settingsPath,
    approvalsDocumentationPath,
    lockedApprovalsRuleName,
  };
  const store = createStore(storeSettings);

  const provide = {
    emptyStateSvgPath: el.dataset.emptyStateSvgPath,
    documentationPath: el.dataset.documentationPath,
  };

  store.dispatch('licenseManagement/setIsAdmin', Boolean(writeLicensePoliciesEndpoint));
  store.dispatch('licenseManagement/setAPISettings', {
    apiUrlManageLicenses: readLicensePoliciesEndpoint,
  });
  store.dispatch('licenseManagement/setKnownLicenses', JSON.parse(softwareLicenses));

  store.dispatch(`${LICENSE_LIST}/setLicensesEndpoint`, projectLicensesEndpoint);

  return new Vue({
    el,
    name: 'LicenseComplianceAppRoot',
    store,
    components: {
      LicenseComplianceApp,
    },
    provide: () => provide,
    render(createElement) {
      return createElement(LicenseComplianceApp);
    },
  });
};
