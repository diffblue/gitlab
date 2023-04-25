export const DEFAULT_DEVFILE_PATH = '.devfile.yaml';
export const DEFAULT_EDITOR = 'webide';
export const WORKSPACE_STATES = {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  starting: 'Starting',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  creating: 'Creating',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  running: 'Running',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  stopped: 'Stopped',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  terminated: 'Terminated',
};
export const DEFAULT_DESIRED_STATE = WORKSPACE_STATES.running;

export const ROUTES = {
  index: 'index',
  create: 'create',
};
