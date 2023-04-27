import { pick } from 'lodash';

export const DEFAULT_DEVFILE_PATH = '.devfile.yaml';
export const DEFAULT_EDITOR = 'webide';
/* eslint-disable @gitlab/require-i18n-strings */
export const WORKSPACE_STATES = {
  creationRequested: 'CreationRequested',
  starting: 'Starting',
  running: 'Running',
  stopping: 'Stopping',
  stopped: 'Stopped',
  terminated: 'Terminated',
  failed: 'Failed',
  error: 'Error',
  unknown: 'Unknown',
};

export const WORKSPACE_DESIRED_STATES = {
  ...pick(WORKSPACE_STATES, 'running', 'stopped', 'terminated'),
  restartRequested: 'RestartRequested',
};
/* eslint-enable @gitlab/require-i18n-strings */

export const DEFAULT_DESIRED_STATE = WORKSPACE_STATES.running;
export const WORKSPACES_LIST_POLL_INTERVAL = 3000;
export const ROUTES = {
  index: 'index',
  create: 'create',
};

export const FILL_CLASS_GREEN = 'gl-fill-green-500';
export const FILL_CLASS_ORANGE = 'gl-fill-orange-500';
