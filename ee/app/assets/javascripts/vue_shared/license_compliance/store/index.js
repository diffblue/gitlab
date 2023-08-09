import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const licenseManagementModule = () => ({
  namespaced: true,
  state: createState(),
  actions,
  getters,
  mutations,
});

export const setupStore = (store) => {
  if (store.hasModule(LICENSE_MANAGEMENT)) {
    return;
  }
  store.registerModule(LICENSE_MANAGEMENT, licenseManagementModule());
};

export default () =>
  new Vuex.Store({
    modules: {
      licenseManagement: licenseManagementModule(),
    },
  });
