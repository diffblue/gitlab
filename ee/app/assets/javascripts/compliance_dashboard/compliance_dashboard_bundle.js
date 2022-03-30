import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ComplianceReport from './components/report.vue';
import { buildDefaultFilterParams } from './utils';

export default () => {
  const el = document.getElementById('js-compliance-report');

  const { mergeCommitsCsvExportPath, groupPath } = el.dataset;

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
};
