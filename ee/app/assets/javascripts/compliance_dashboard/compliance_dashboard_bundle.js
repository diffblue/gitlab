import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';
import resolvers from './graphql/resolvers';
import ComplianceDashboard from './components/dashboard.vue';
import ComplianceReport from './components/report.vue';

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
      defaultClient: createDefaultClient(resolvers),
    });

    const defaultQuery = queryToObject(window.location.search, { gatherArrays: true });

    return new Vue({
      el,
      apolloProvider,
      render: (createElement) =>
        createElement(ComplianceReport, {
          props: {
            mergeCommitsCsvExportPath,
            groupPath,
            defaultQuery,
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
