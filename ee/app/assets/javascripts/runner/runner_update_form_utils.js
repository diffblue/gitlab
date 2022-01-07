import {
  modelToUpdateMutationVariables as ceModelToUpdateMutationVariables,
  runnerToModel as ceRunnerToModel,
} from '~/runner/runner_update_form_utils';

export const runnerToModel = (runner) => {
  return {
    ...ceRunnerToModel(runner),
    privateProjectsMinutesCostFactor: runner?.privateProjectsMinutesCostFactor,
    publicProjectsMinutesCostFactor: runner?.publicProjectsMinutesCostFactor,
  };
};

export const modelToUpdateMutationVariables = (model) => {
  const { privateProjectsMinutesCostFactor, publicProjectsMinutesCostFactor } = model;

  return {
    input: {
      ...ceModelToUpdateMutationVariables(model).input,
      privateProjectsMinutesCostFactor:
        privateProjectsMinutesCostFactor !== '' ? privateProjectsMinutesCostFactor : null,
      publicProjectsMinutesCostFactor:
        publicProjectsMinutesCostFactor !== '' ? publicProjectsMinutesCostFactor : null,
    },
  };
};
