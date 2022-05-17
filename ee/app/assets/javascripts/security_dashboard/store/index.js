import Vue from 'vue';
import Vuex from 'vuex';

import filters from './modules/filters/index';
import pipelineJobs from './modules/pipeline_jobs/index';
import vulnerabilities from './modules/vulnerabilities/index';
import vulnerableProjects from './modules/vulnerable_projects/index';
import mediator from './plugins/mediator';

Vue.use(Vuex);

export const getStoreConfig = () => ({
  modules: {
    vulnerableProjects,
    filters,
    vulnerabilities,
    pipelineJobs,
  },
});

export default () =>
  new Vuex.Store({
    ...getStoreConfig(),
    plugins: [mediator],
  });
