import filters from './modules/filters/index';
import pipelineJobs from './modules/pipeline_jobs/index';
import vulnerabilities from './modules/vulnerabilities/index';
import vulnerableProjects from './modules/vulnerable_projects/index';
import mediator from './plugins/mediator';

export const setupStore = (store) => {
  mediator(store);
  Object.entries({
    vulnerableProjects,
    filters,
    vulnerabilities,
    pipelineJobs,
  }).forEach(([name, module]) => {
    store.registerModule(name, module);
  });
};
