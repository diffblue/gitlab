import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { VARIANT_SUCCESS } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';

import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { runnerFormData } from 'jest/ci/runner/mock_data';
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';
import RunnerUpdateForm from '~/ci/runner/components/runner_update_form.vue';
import runnerUpdateMutation from '~/ci/runner/graphql/edit/runner_update.mutation.graphql';
import { INSTANCE_TYPE } from '~/ci/runner/constants';

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

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
          runner: null,
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
    expect(visitUrl).toHaveBeenCalledWith(mockRunnerPath);
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
      beforeEach(async () => {
        gon.dot_com = true;

        createComponent();

        await wrapper.setProps({
          runnerType: INSTANCE_TYPE,
          loading: false,
          runner: mockRunner,
        });

        await waitForPromises();
      });

      it('the form contains CI minute cost factors', () => {
        expect(findPrivateProjectsCostFactor().exists()).toBe(true);
        expect(findPublicProjectsCostFactor().exists()).toBe(true);
      });

      describe('On submit, runner gets updated', () => {
        it.each`
          test                         | findInput                             | value    | submitted
          ${'private minutes'}         | ${findPrivateProjectsCostFactorInput} | ${'1.5'} | ${{ privateProjectsMinutesCostFactor: 1.5 }}
          ${'private minutes to null'} | ${findPrivateProjectsCostFactorInput} | ${''}    | ${{ privateProjectsMinutesCostFactor: null }}
          ${'public minutes'}          | ${findPublicProjectsCostFactorInput}  | ${'0.5'} | ${{ publicProjectsMinutesCostFactor: 0.5 }}
          ${'public minutes to null'}  | ${findPublicProjectsCostFactorInput}  | ${''}    | ${{ publicProjectsMinutesCostFactor: null }}
        `("Field updates runner's $test", async ({ findInput, value, submitted }) => {
          await findInput().setValue(value);
          await submitFormAndWait();

          expectToHaveSubmittedRunnerContaining({
            id: mockRunner.id,
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

    beforeEach(async () => {
      createComponent({
        provide: {
          glFeatures: {
            runnerMaintenanceNote: true,
          },
        },
      });

      await wrapper.setProps({
        loading: false,
        runner,
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
