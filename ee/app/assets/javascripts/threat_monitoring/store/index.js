import Vue from 'vue';
import Vuex from 'vuex';
import networkPolicies from './modules/network_policies';
import threatMonitoring from './modules/threat_monitoring';
import scanResultPolicies from './modules/scan_result_policies';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      threatMonitoring: threatMonitoring(),
      networkPolicies: networkPolicies(),
      scanResultPolicies: scanResultPolicies(),
    },
  });
