import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ReportsApp from './components/reports_app.vue';

export default () => {
  const el = document.getElementById('js-compliance-report');

  const { mergeCommitsCsvExportPath, groupPath } = el.dataset;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render: (createElement) =>
      createElement(ReportsApp, {
        props: {
          mergeCommitsCsvExportPath,
          groupPath,
        },
      }),
  });
};
