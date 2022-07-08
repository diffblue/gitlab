import Vue from 'vue';
import Vuex from 'vuex';
import PipelineSecurityDashboard from './components/pipeline/pipeline_security_dashboard.vue';
import apolloProvider from './graphql/provider';
import createRouter from './router';
import { getPipelineReportOptions } from './utils/pipeline_report_options';

// This can be removed when the migration to GraphQL is completed.
// Though, if we complete the pipeline tabs migration first, we will be removing this whole file.
Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-security-report-app');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    apolloProvider,
    router: createRouter(),
    store: new Vuex.Store(),
    provide: getPipelineReportOptions(el.dataset),
    render(createElement) {
      return createElement(PipelineSecurityDashboard);
    },
  });
};
