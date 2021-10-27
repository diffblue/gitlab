import { INVALID_CURRENT_ENVIRONMENT_NAME } from '../../../constants';

export const currentEnvironment = ({ currentEnvironmentId, environments }) =>
  environments.find((environment) => environment.id === currentEnvironmentId);

export const currentEnvironmentName = (state, getters) =>
  getters.currentEnvironment?.name ?? INVALID_CURRENT_ENVIRONMENT_NAME;

export const currentEnvironmentGid = (state, getters) => getters.currentEnvironment?.global_id;

export const canChangeEnvironment = ({ environments }) => Boolean(environments.length);
