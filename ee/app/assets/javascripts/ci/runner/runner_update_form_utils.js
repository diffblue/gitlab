import {
  modelToUpdateMutationVariables as ceModelToUpdateMutationVariables,
  runnerToModel as ceRunnerToModel,
} from '~/ci/runner/runner_update_form_utils';

export const runnerToModel = (runner) => {
  return {
    ...ceRunnerToModel(runner),
    maintenanceNote: runner?.maintenanceNote,
    privateProjectsMinutesCostFactor: runner?.privateProjectsMinutesCostFactor,
    publicProjectsMinutesCostFactor: runner?.publicProjectsMinutesCostFactor,
  };
};

export const modelToUpdateMutationVariables = (model) => {
  const {
    privateProjectsMinutesCostFactor,
    publicProjectsMinutesCostFactor,
    maintenanceNote,
  } = model;

  return {
    input: {
      ...ceModelToUpdateMutationVariables(model).input,
      maintenanceNote,
      privateProjectsMinutesCostFactor:
        privateProjectsMinutesCostFactor !== '' ? privateProjectsMinutesCostFactor : null,
      publicProjectsMinutesCostFactor:
        publicProjectsMinutesCostFactor !== '' ? publicProjectsMinutesCostFactor : null,
    },
  };
};
