import {
  modelToUpdateMutationVariables,
  runnerToModel,
} from 'ee/ci/runner/runner_update_form_utils';

const mockRunnerId = 'gid://gitlab/Ci::Runner/1';
const mockPrivateFactor = 1;
const mockPublicFactor = 0.5;

describe('ee/ci/runner/runner_update_form_utils', () => {
  describe('runnerToModel', () => {
    it('collects project minutes factor', () => {
      expect(
        runnerToModel({
          id: mockRunnerId,
          privateProjectsMinutesCostFactor: mockPrivateFactor,
          publicProjectsMinutesCostFactor: mockPublicFactor,
        }),
      ).toMatchObject({
        id: mockRunnerId,
        privateProjectsMinutesCostFactor: mockPrivateFactor,
        publicProjectsMinutesCostFactor: mockPublicFactor,
      });
    });

    it('collects null project minutes factor', () => {
      expect(
        runnerToModel({
          id: mockRunnerId,
          privateProjectsMinutesCostFactor: undefined,
          publicProjectsMinutesCostFactor: undefined,
        }),
      ).toMatchObject({
        id: mockRunnerId,
        privateProjectsMinutesCostFactor: undefined,
        publicProjectsMinutesCostFactor: undefined,
      });
    });

    it('collects null runner', () => {
      expect(runnerToModel(null)).toMatchObject({
        privateProjectsMinutesCostFactor: undefined,
        publicProjectsMinutesCostFactor: undefined,
      });
    });
  });

  describe('modelToUpdateMutationVariables', () => {
    it('gets project minutes factor as input', () => {
      expect(
        modelToUpdateMutationVariables({
          id: mockRunnerId,
          privateProjectsMinutesCostFactor: mockPrivateFactor,
          publicProjectsMinutesCostFactor: mockPublicFactor,
        }),
      ).toMatchObject({
        input: {
          id: mockRunnerId,
          privateProjectsMinutesCostFactor: mockPrivateFactor,
          publicProjectsMinutesCostFactor: mockPublicFactor,
        },
      });
    });

    it('gets empty project minutes factor as input', () => {
      expect(
        modelToUpdateMutationVariables({
          privateProjectsMinutesCostFactor: '',
          publicProjectsMinutesCostFactor: '',
        }),
      ).toMatchObject({
        input: {
          privateProjectsMinutesCostFactor: null,
          publicProjectsMinutesCostFactor: null,
        },
      });
    });
  });
});
