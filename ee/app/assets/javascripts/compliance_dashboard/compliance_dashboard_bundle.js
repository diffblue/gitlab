import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';

import createDefaultClient from '~/lib/graphql';

import { createRouter } from 'ee/compliance_dashboard/router';
import ReportsApp from './components/reports_app.vue';

export default () => {
  const el = document.getElementById('js-compliance-report');

  const {
    basePath,
    mergeCommitsCsvExportPath,
    groupPath,
    groupEditPath,
    rootAncestorPath,
    newGroupComplianceFrameworkPath,
    pipelineConfigurationFullPathEnabled,
  } = el.dataset;

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const router = createRouter(basePath, {
    mergeCommitsCsvExportPath,
    newGroupComplianceFrameworkPath,
    groupPath,
    rootAncestorPath,
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'ComplianceReportsApp',
    router,
    provide: {
      groupPath,
      groupEditPath,
      pipelineConfigurationFullPathEnabled,
    },
    render: (createElement) =>
      createElement(ReportsApp, {
        props: {
          mergeCommitsCsvExportPath,
          newGroupComplianceFrameworkPath,
        },
      }),
  });
};
