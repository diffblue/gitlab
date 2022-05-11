import Vue from 'vue';
import Vuex from 'vuex';
import threatMonitoring from './modules/threat_monitoring';
import scanResultPolicies from './modules/scan_result_policies';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      threatMonitoring: threatMonitoring(),
      scanResultPolicies: scanResultPolicies(),
    },
  });
