import { provide as ceProvide } from '~/ci/runner/admin_runners/provide';

/**
 * Provides global values to the admin runners app.
 *
 * Includes a runnerDashboardPath, which is to be shown when the dashboard is
 * enabled.
 *
 * @param {Object} `data-` HTML attributes of the mounting point
 * @returns An object with properties to use provide/inject of the EE root app.
 */
export const provide = (elDataset) => {
  const { runnerDashboardPath } = elDataset;

  return {
    ...ceProvide(elDataset),
    runnerDashboardPath,
  };
};
