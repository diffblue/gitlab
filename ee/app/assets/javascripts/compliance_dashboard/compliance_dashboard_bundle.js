import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { parseBoolean } from '~/lib/utils/common_utils';

import createDefaultClient from '~/lib/graphql';

import { createRouter } from 'ee/compliance_dashboard/router';
import ReportsApp from './components/reports_app.vue';

export default () => {
  const el = document.getElementById('js-compliance-report');

  const {
    basePath,
    canAddEdit,
    mergeCommitsCsvExportPath,
    violationsCsvExportPath,
    frameworksCsvExportPath,
    groupPath,
    rootAncestorPath,
    pipelineConfigurationFullPathEnabled,
    pipelineConfigurationEnabled,
    adherenceReportUiEnabled,
    complianceFrameworkReportUiEnabled,
  } = el.dataset;

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const router = createRouter(basePath, {
    mergeCommitsCsvExportPath,
    groupPath,
    rootAncestorPath,
    adherenceReportUiEnabled: parseBoolean(adherenceReportUiEnabled),
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'ComplianceReportsApp',
    router,
    provide: {
      groupPath,
      canAddEdit,
      pipelineConfigurationFullPathEnabled: parseBoolean(pipelineConfigurationFullPathEnabled),
      pipelineConfigurationEnabled: parseBoolean(pipelineConfigurationEnabled),
      adherenceReportUiEnabled: parseBoolean(adherenceReportUiEnabled),
      complianceFrameworkReportUiEnabled: parseBoolean(complianceFrameworkReportUiEnabled),
    },
    render: (createElement) =>
      createElement(ReportsApp, {
        props: {
          mergeCommitsCsvExportPath,
          violationsCsvExportPath,
          frameworksCsvExportPath,
        },
      }),
  });
};
