import filters from './modules/filters/index';
import pipelineJobs from './modules/pipeline_jobs/index';
import vulnerabilities from './modules/vulnerabilities/index';
import mediator from './plugins/mediator';

export const setupStore = (store) => {
  mediator(store);
  Object.entries({
    filters,
    vulnerabilities,
    pipelineJobs,
  }).forEach(([name, module]) => {
    store.registerModule(name, module);
  });
};
