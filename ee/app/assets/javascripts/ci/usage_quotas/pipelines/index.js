import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import PipelineUsageApp from './components/app.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-pipeline-usage-app');

  if (!el) {
    return false;
  }

  const {
    pageSize,
    namespacePath,
    namespaceId,
    namespaceActualPlanName,
    userNamespace,
    ciMinutesAnyProjectEnabled,
    ciMinutesDisplayMinutesAvailableData,
    ciMinutesLastResetDate,
    ciMinutesMonthlyMinutesLimit,
    ciMinutesMonthlyMinutesUsed,
    ciMinutesMonthlyMinutesUsedPercentage,
    ciMinutesPurchasedMinutesLimit,
    ciMinutesPurchasedMinutesUsed,
    ciMinutesPurchasedMinutesUsedPercentage,
    buyAdditionalMinutesPath,
    buyAdditionalMinutesTarget,
  } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'PipelinesUsageView',
    provide: {
      pageSize: Number(pageSize),
      namespacePath,
      namespaceId,
      namespaceActualPlanName,
      userNamespace: parseBoolean(userNamespace),
      ciMinutesAnyProjectEnabled: parseBoolean(ciMinutesAnyProjectEnabled),
      ciMinutesDisplayMinutesAvailableData: parseBoolean(ciMinutesDisplayMinutesAvailableData),
      ciMinutesLastResetDate,
      // Limit and Usage could be a number or a string (e.g. `Unlimited`) so we shouldn't parse these
      ciMinutesMonthlyMinutesLimit,
      ciMinutesMonthlyMinutesUsed,
      ciMinutesMonthlyMinutesUsedPercentage,
      ciMinutesPurchasedMinutesLimit,
      ciMinutesPurchasedMinutesUsed,
      ciMinutesPurchasedMinutesUsedPercentage,
      buyAdditionalMinutesPath,
      buyAdditionalMinutesTarget,
    },
    apolloProvider,
    render(createElement) {
      return createElement(PipelineUsageApp);
    },
  });
};
