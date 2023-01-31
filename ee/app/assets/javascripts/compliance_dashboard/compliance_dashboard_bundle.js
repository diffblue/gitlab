import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ComplianceReport from './components/violations_report/report.vue';
import ReportsApp from './components/reports_app.vue';
import { buildDefaultFilterParams } from './utils';

export default () => {
  const el = document.getElementById('js-compliance-report');

  const { mergeCommitsCsvExportPath, groupPath } = el.dataset;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const defaultFilterParams = buildDefaultFilterParams(window.location.search);

  const component = gon.features.complianceFrameworksReport ? ReportsApp : ComplianceReport;

  return new Vue({
    el,
    apolloProvider,
    render: (createElement) =>
      createElement(component, {
        props: {
          mergeCommitsCsvExportPath,
          groupPath,
          defaultFilterParams,
        },
      }),
  });
};
