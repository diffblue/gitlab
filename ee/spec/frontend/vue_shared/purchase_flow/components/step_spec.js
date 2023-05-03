import { GlButton, GlFormGroup } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import StepHeader from 'ee/vue_shared/purchase_flow/components/step_header.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import updateStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/update_active_step.mutation.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { STEPS } from '../mock_data';
import { createMockApolloProvider } from '../spec_helper';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('Step', () => {
  let wrapper;
  const initialProps = {
    stepId: STEPS[1].id,
    isValid: true,
    title: 'title',
    nextStepButtonText: 'next',
  };
  const summaryClass = 'step-summary';

  function activateFirstStep(apolloProvider) {
    return apolloProvider.clients.defaultClient.mutate({
      mutation: updateStepMutation,
      variables: { id: STEPS[0].id },
    });
  }
  function createComponent(options = {}) {
    const { apolloProvider, propsData } = options;

    return shallowMountExtended(Step, {
      propsData: { ...initialProps, ...propsData },
      apolloProvider,
      slots: {
        summary: `<p class="${summaryClass}">Some summary</p>`,
      },
      stubs: {
        StepHeader,
      },
    });
  }

  afterEach(() => {
    createAlert.mockClear();
  });

  const findStepHeader = () => wrapper.findComponent(StepHeader);
  const findEditButton = () => findStepHeader().findComponent(GlButton);
  const findActiveStepBody = () => wrapper.findByTestId('active-step-body');
  const findNextButton = () => findActiveStepBody().findComponent(GlButton);
  const findStepSummary = () => wrapper.find(`.${summaryClass}`);

  describe('Step Body', () => {
    it('should display the step body when this step is the current step', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(findActiveStepBody().attributes('style')).toBeUndefined();
    });

    it('should not display the step body when this step is not the current step', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      await activateFirstStep(mockApollo);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(findActiveStepBody().attributes('style')).toBe('display: none;');
    });
  });

  describe('Step Summary', () => {
    it('should be shown when this step is valid and not active', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      await activateFirstStep(mockApollo);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(findStepSummary().exists()).toBe(true);
    });

    it('displays an error when editing a wrong step', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);

      await activateFirstStep(mockApollo);
      wrapper = createComponent({
        propsData: { stepId: 'does not exist' },
        apolloProvider: mockApollo,
      });

      findEditButton().vm.$emit('click');
      await waitForPromises();

      expect(createAlert.mock.calls).toHaveLength(1);
      expect(createAlert.mock.calls[0][0]).toMatchObject({
        message: GENERAL_ERROR_MESSAGE,
        captureError: true,
        error: expect.any(Error),
      });
    });

    it('should not be shown when this step is not valid and not active', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      await activateFirstStep(mockApollo);
      wrapper = createComponent({ propsData: { isValid: false }, apolloProvider: mockApollo });

      expect(findStepSummary().exists()).toBe(false);
    });

    it('should not be shown when this step is valid and active', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(findStepSummary().exists()).toBe(false);
    });

    it('should not be shown when this step is not valid and active', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ propsData: { isValid: false }, apolloProvider: mockApollo });

      expect(findStepSummary().exists()).toBe(false);
    });
  });

  it('should pass correct props to form component', () => {
    wrapper = createComponent({
      propsData: { isValid: false, errorMessage: 'Input value is invalid!' },
    });

    expect(wrapper.findComponent(GlFormGroup).attributes('invalid-feedback')).toBe(
      'Input value is invalid!',
    );
  });

  describe('isEditable', () => {
    it('should set the isEditable property to true when this step is finished and comes before the current step', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ propsData: { stepId: STEPS[0].id }, apolloProvider: mockApollo });

      expect(findStepHeader().props('isEditable')).toBe(true);
    });
  });

  describe('Showing the summary', () => {
    it('shows the summary when this step is finished', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      await activateFirstStep(mockApollo);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(findStepSummary().exists()).toBe(true);
    });

    it('does not show the summary when this step is not finished', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(findStepSummary().exists()).toBe(false);
    });
  });

  describe('Next button', () => {
    it('shows the next button when the text was passed', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(findNextButton().text()).toBe('next');
    });

    it('does not show the next button when no text was passed', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({
        propsData: { nextStepButtonText: '' },
        apolloProvider: mockApollo,
      });

      expect(findNextButton().exists()).toBe(false);
    });

    it('is disabled when this step is not valid', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ propsData: { isValid: false }, apolloProvider: mockApollo });

      expect(wrapper.findComponent(GlButton).attributes('disabled')).toBeDefined();
    });

    it('is enabled when this step is valid', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(findNextButton().attributes('disabled')).toBeUndefined();
    });

    it('displays an error if navigating too far', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 2);
      wrapper = createComponent({ propsData: { stepId: STEPS[2].id }, apolloProvider: mockApollo });

      findNextButton().vm.$emit('click');
      await waitForPromises();

      expect(createAlert.mock.calls).toHaveLength(1);
      expect(createAlert.mock.calls[0][0]).toMatchObject({
        message: GENERAL_ERROR_MESSAGE,
        captureError: true,
        error: expect.any(Error),
      });
    });
  });

  describe('emitted events', () => {
    it('emits stepEdit', async () => {
      // start with the third step (STEPS[2]) as the activeStep
      const mockApollo = createMockApolloProvider(STEPS, 2);
      // grab a wrapper for the second step (STEPS[1])
      wrapper = createComponent({ propsData: { stepId: STEPS[1].id }, apolloProvider: mockApollo });

      // click the "Edit" button for the second step
      findEditButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted().stepEdit[0]).toEqual(['secondStep']);
    });

    it('emits nextStep on step transition', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ propsData: { stepId: STEPS[1].id }, apolloProvider: mockApollo });
      await activateFirstStep(mockApollo);

      wrapper.findComponent(GlButton).vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted().nextStep).toHaveLength(1);
    });
  });
});
