import { GlForm } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { runnerData } from 'jest/runner/mock_data';
import { createAlert, VARIANT_SUCCESS } from '~/flash';
import RunnerUpdateForm from '~/runner/components/runner_update_form.vue';
import runnerUpdateMutation from '~/runner/graphql/details/runner_update.mutation.graphql';

jest.mock('~/flash');

const mockRunner = runnerData.data.runner;

Vue.use(VueApollo);

describe('RunnerUpdateForm', () => {
  let wrapper;
  let runnerUpdateHandler;

  const findForm = () => wrapper.findComponent(GlForm);

  const findPrivateProjectsCostFactor = () =>
    wrapper.findByTestId('runner-field-private-projects-cost-factor');
  const findPublicProjectsCostFactor = () =>
    wrapper.findByTestId('runner-field-public-projects-cost-factor');
  const findPrivateProjectsCostFactorInput = () => findPrivateProjectsCostFactor().find('input');
  const findPublicProjectsCostFactorInput = () => findPublicProjectsCostFactor().find('input');

  const findSubmit = () => wrapper.find('[type="submit"]');
  const findSubmitDisabledAttr = () => findSubmit().attributes('disabled');
  const submitForm = () => findForm().trigger('submit');
  const submitFormAndWait = () => submitForm().then(waitForPromises);

  const createComponent = ({ props } = {}) => {
    wrapper = extendedWrapper(
      mount(RunnerUpdateForm, {
        propsData: {
          runner: mockRunner,
          ...props,
        },
        apolloProvider: createMockApollo([[runnerUpdateMutation, runnerUpdateHandler]]),
      }),
    );
  };

  const expectToHaveSubmittedRunnerContaining = (submittedRunner) => {
    expect(runnerUpdateHandler).toHaveBeenCalledTimes(1);
    expect(runnerUpdateHandler).toHaveBeenCalledWith({
      input: expect.objectContaining(submittedRunner),
    });

    expect(createAlert).toHaveBeenLastCalledWith({
      message: expect.stringContaining('saved'),
      variant: VARIANT_SUCCESS,
    });

    expect(findSubmitDisabledAttr()).toBeUndefined();
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

  afterEach(() => {
    wrapper.destroy();
  });

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
