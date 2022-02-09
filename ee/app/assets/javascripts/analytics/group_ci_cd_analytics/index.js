import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CiCdAnalyticsApp from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-group-ci-cd-analytics-app');

  if (!el) return false;

  const { fullPath, groupId, pipelineGroupUsageQuotaPath, canViewGroupUsageQuota } = el.dataset;

  const shouldRenderDoraCharts = parseBoolean(el.dataset.shouldRenderDoraCharts);
  const canViewGroupUsageQuotaBoolean = parseBoolean(canViewGroupUsageQuota);

  return new Vue({
    el,
    apolloProvider,
    provide: {
      groupPath: fullPath,
      shouldRenderDoraCharts,
      groupId,
      pipelineGroupUsageQuotaPath,
      canViewGroupUsageQuotaBoolean,
    },
    render: (createElement) => createElement(CiCdAnalyticsApp),
  });
};
