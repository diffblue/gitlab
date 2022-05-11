import Vue from 'vue';
import Vuex from 'vuex';
import scanResultPolicies from './modules/scan_result_policies';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      scanResultPolicies: scanResultPolicies(),
    },
  });
