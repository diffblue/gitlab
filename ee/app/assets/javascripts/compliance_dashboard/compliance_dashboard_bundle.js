import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import ComplianceDashboard from './components/dashboard.vue';
import ComplianceReport from './components/report.vue';
import { buildDefaultFilterParams } from './utils';

export default () => {
  const el = document.getElementById('js-compliance-report');

  const {
    mergeRequests,
    emptyStateSvgPath,
    isLastPage,
    mergeCommitsCsvExportPath,
    groupPath,
  } = el.dataset;

  if (gon.features.complianceViolationsReport) {
    Vue.use(VueApollo);

    const apolloProvider = new VueApollo({
      defaultClient: createDefaultClient(),
    });

    const defaultFilterParams = buildDefaultFilterParams(window.location.search);

    return new Vue({
      el,
      apolloProvider,
      render: (createElement) =>
        createElement(ComplianceReport, {
          props: {
            mergeCommitsCsvExportPath,
            groupPath,
            defaultFilterParams,
          },
        }),
    });
  }

  return new Vue({
    el,
    render: (createElement) =>
      createElement(ComplianceDashboard, {
        props: {
          mergeRequests: JSON.parse(mergeRequests),
          isLastPage: parseBoolean(isLastPage),
          emptyStateSvgPath,
          mergeCommitsCsvExportPath,
        },
      }),
  });
};
