import Vue from 'vue';
import Vuex from 'vuex';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import networkPolicies from './modules/network_policies';
import threatMonitoring from './modules/threat_monitoring';
import threatMonitoringStatistics from './modules/threat_monitoring_statistics';
import scanResultPolicies from './modules/scan_result_policies';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      threatMonitoring: threatMonitoring(),
      threatMonitoringNetworkPolicy: threatMonitoringStatistics((payload) => {
        const {
          opsRate,
          opsTotal: { total, drops },
        } = convertObjectPropsToCamelCase(payload);
        const formatFunc = ([timestamp, val]) => [new Date(timestamp * 1000), val];

        return {
          total,
          anomalous: drops / total,
          history: {
            nominal: opsRate.total.map(formatFunc),
            anomalous: opsRate.drops.map(formatFunc),
          },
        };
      }),
      networkPolicies: networkPolicies(),
      scanResultPolicies: scanResultPolicies(),
    },
  });
