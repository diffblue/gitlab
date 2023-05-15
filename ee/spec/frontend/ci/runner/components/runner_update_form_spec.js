import { GlForm } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { runnerFormData } from 'jest/ci/runner/mock_data';
import { VARIANT_SUCCESS } from '~/alert';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';
import RunnerUpdateForm from '~/ci/runner/components/runner_update_form.vue';
import runnerUpdateMutation from '~/ci/runner/graphql/edit/runner_update.mutation.graphql';

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/lib/utils/url_utility');

const mockRunner = runnerFormData.data.runner;
const mockRunnerPath = '/admin/runners/1';

Vue.use(VueApollo);

describe('RunnerUpdateForm', () => {
  let wrapper;
  let runnerUpdateHandler;

  const findForm = () => wrapper.findComponent(GlForm);

  const findMaintenanceNote = () => wrapper.findByTestId('runner-field-maintenance-note');
  const findPrivateProjectsCostFactor = () =>
    wrapper.findByTestId('runner-field-private-projects-cost-factor');
  const findPublicProjectsCostFactor = () =>
    wrapper.findByTestId('runner-field-public-projects-cost-factor');

  const findMaintenanceNoteTextarea = () => findMaintenanceNote().find('textarea');
  const findPrivateProjectsCostFactorInput = () => findPrivateProjectsCostFactor().find('input');
  const findPublicProjectsCostFactorInput = () => findPublicProjectsCostFactor().find('input');

  const submitForm = () => findForm().trigger('submit');
  const submitFormAndWait = () => submitForm().then(waitForPromises);

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = extendedWrapper(
      mount(RunnerUpdateForm, {
        propsData: {
          runner: mockRunner,
          runnerPath: mockRunnerPath,
          ...props,
        },
        apolloProvider: createMockApollo([[runnerUpdateMutation, runnerUpdateHandler]]),
        ...options,
      }),
    );
  };

  const expectToHaveSubmittedRunnerContaining = (submittedRunner) => {
    expect(runnerUpdateHandler).toHaveBeenCalledTimes(1);
    expect(runnerUpdateHandler).toHaveBeenCalledWith({
      input: expect.objectContaining(submittedRunner),
    });

    expect(saveAlertToLocalStorage).toHaveBeenCalledWith(
      expect.objectContaining({
        message: expect.any(String),
        variant: VARIANT_SUCCESS,
      }),
    );
    expect(redirectTo).toHaveBeenCalledWith(mockRunnerPath); // eslint-disable-line import/no-deprecated
  };

  beforeEach(() => {
    runnerUpdateHandler = jest.fn().mockImplementation(({ input }) => {
      return Promise.resolve({
        data: {
          runnerUpdate: {
            runner: {
              ...mockRunner,
              ...input,
            },
            errors: [],
          },
        },
      });
    });
  });

  describe('Cost factor fields', () => {
    describe('When on .com', () => {
      beforeEach(() => {
        gon.dot_com = true;

        createComponent();
      });

      it('the form contains CI minute cost factors', () => {
        expect(findPrivateProjectsCostFactor().exists()).toBe(true);
        expect(findPublicProjectsCostFactor().exists()).toBe(true);
      });

      describe('On submit, runner gets updated', () => {
        it.each`
          test                         | initialValue                               | findInput                             | value    | submitted
          ${'private minutes'}         | ${{ privateProjectsMinutesCostFactor: 1 }} | ${findPrivateProjectsCostFactorInput} | ${'1.5'} | ${{ privateProjectsMinutesCostFactor: 1.5 }}
          ${'private minutes to null'} | ${{ privateProjectsMinutesCostFactor: 1 }} | ${findPrivateProjectsCostFactorInput} | ${''}    | ${{ privateProjectsMinutesCostFactor: null }}
          ${'public minutes'}          | ${{ publicProjectsMinutesCostFactor: 0 }}  | ${findPublicProjectsCostFactorInput}  | ${'0.5'} | ${{ publicProjectsMinutesCostFactor: 0.5 }}
          ${'public minutes to null'}  | ${{ publicProjectsMinutesCostFactor: 0 }}  | ${findPublicProjectsCostFactorInput}  | ${''}    | ${{ publicProjectsMinutesCostFactor: null }}
        `("Field updates runner's $test", async ({ initialValue, findInput, value, submitted }) => {
          const runner = { ...mockRunner, ...initialValue };
          createComponent({ props: { runner } });

          await findInput().setValue(value);
          await submitFormAndWait();

          expectToHaveSubmittedRunnerContaining({
            id: runner.id,
            ...submitted,
          });
        });
      });
    });

    describe('When not on .com', () => {
      beforeEach(() => {
        gon.dot_com = false;

        createComponent();
      });

      it('the form does not contain CI minute cost factors', () => {
        expect(findPrivateProjectsCostFactor().exists()).toBe(false);
        expect(findPublicProjectsCostFactor().exists()).toBe(false);
      });
    });
  });

  describe('Maintenance note field', () => {
    const value = 'Note';
    const runner = { ...mockRunner, maintenanceNote: value };

    beforeEach(() => {
      createComponent({
        props: { runner },
        provide: {
          glFeatures: {
            runnerMaintenanceNote: true,
          },
        },
      });
    });

    it('shows maintenance note field', () => {
      expect(findMaintenanceNote().exists()).toBe(true);
      expect(findMaintenanceNoteTextarea().element.value).toBe(value);
    });

    it('submits value', async () => {
      const newValue = 'New note';

      await findMaintenanceNoteTextarea().setValue(newValue);
      await submitFormAndWait();

      expectToHaveSubmittedRunnerContaining({
        id: runner.id,
        maintenanceNote: newValue,
      });
    });
  });
});
