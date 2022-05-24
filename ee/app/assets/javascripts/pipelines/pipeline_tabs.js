import { createAppOptions as createAppOptionsCE } from '~/pipelines/pipeline_tabs';

export const createAppOptions = (...args) => {
  const appOptionsCE = createAppOptionsCE(...args);

  // We only return CE options for now.
  // In future MRs, this will be extended with EE-specific options.
  return appOptionsCE;
};
