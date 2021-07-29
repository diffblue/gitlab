import Vuex from 'vuex';
import securityConfigurationModule from 'ee/security_configuration/modules/configuration';
import modalModule from '~/vuex_shared/modules/modal';
import state from './state';

export const createStoreOptions = (approvalsModules, settings) => ({
  state: state(settings),
  modules: {
    ...approvalsModules,
    createModal: modalModule(),
    deleteModal: modalModule(),
    securityConfiguration: securityConfigurationModule({
      securityConfigurationPath: settings?.securityConfigurationPath || '',
    }),
  },
});

export default (approvalModules, settings = {}) =>
  new Vuex.Store(createStoreOptions(approvalModules, settings));
