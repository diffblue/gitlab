import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ComplianceDashboard from './components/dashboard.vue';

export default () => {
  const el = document.getElementById('js-compliance-report');

  const { mergeRequests, emptyStateSvgPath, isLastPage, mergeCommitsCsvExportPath } = el.dataset;

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
