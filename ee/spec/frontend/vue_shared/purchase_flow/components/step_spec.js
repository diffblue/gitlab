import { GlButton, GlFormGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import StepSummary from 'ee/vue_shared/purchase_flow/components/step_summary.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import updateStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/update_active_step.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import flash from '~/flash';
import { STEPS } from '../mock_data';
import { createMockApolloProvider } from '../spec_helper';

Vue.use(VueApollo);

jest.mock('~/flash');

describe('Step', () => {
  let wrapper;
  const initialProps = {
    stepId: STEPS[1].id,
    isValid: true,
    title: 'title',
    nextStepButtonText: 'next',
  };

  function activateFirstStep(apolloProvider) {
    return apolloProvider.clients.defaultClient.mutate({
      mutation: updateStepMutation,
      variables: { id: STEPS[0].id },
    });
  }
  function createComponent(options = {}) {
    const { apolloProvider, propsData } = options;

    return shallowMount(Step, {
      propsData: { ...initialProps, ...propsData },
      apolloProvider,
      stubs: {
        StepSummary,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    flash.mockClear();
  });

  describe('Step Body', () => {
    it('should display the step body when this step is the current step', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(wrapper.find('.card > div').attributes('style')).toBeUndefined();
    });

    it('should not display the step body when this step is not the current step', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      await activateFirstStep(mockApollo);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(wrapper.find('.card > div').attributes('style')).toBe('display: none;');
    });
  });

  describe('Step Summary', () => {
    it('should be shown when this step is valid and not active', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      await activateFirstStep(mockApollo);
      wrapper = createComponent({ apolloProvider: mockApollo });
      expect(wrapper.findComponent(StepSummary).exists()).toBe(true);
    });

    it('displays an error when editing a wrong step', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);

      await activateFirstStep(mockApollo);
      wrapper = createComponent({
        propsData: { stepId: 'does not exist' },
        apolloProvider: mockApollo,
      });

      wrapper.findComponent(StepSummary).findComponent(GlButton).vm.$emit('click');
      await waitForPromises();

      expect(flash.mock.calls).toHaveLength(1);
      expect(flash.mock.calls[0][0]).toMatchObject({
        message: GENERAL_ERROR_MESSAGE,
        captureError: true,
        error: expect.any(Error),
      });
    });

    it('should not be shown when this step is not valid and not active', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      await activateFirstStep(mockApollo);
      wrapper = createComponent({ propsData: { isValid: false }, apolloProvider: mockApollo });

      expect(wrapper.findComponent(StepSummary).exists()).toBe(false);
    });

    it('should not be shown when this step is valid and active', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(wrapper.findComponent(StepSummary).exists()).toBe(false);
    });

    it('should not be shown when this step is not valid and active', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ propsData: { isValid: false }, apolloProvider: mockApollo });

      expect(wrapper.findComponent(StepSummary).exists()).toBe(false);
    });

    it('should pass correct props to form component', () => {
      wrapper = createComponent({
        propsData: { errorMessage: 'Input value is invalid!' },
      });

      expect(wrapper.findComponent(GlFormGroup).attributes('invalid-feedback')).toBe(
        'Input value is invalid!',
      );
    });
  });

  describe('isEditable', () => {
    it('should set the isEditable property to true when this step is finished and comes before the current step', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ propsData: { stepId: STEPS[0].id }, apolloProvider: mockApollo });

      expect(wrapper.findComponent(StepSummary).props('isEditable')).toBe(true);
    });
  });

  describe('Showing the summary', () => {
    it('shows the summary when this step is finished', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      await activateFirstStep(mockApollo);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(wrapper.findComponent(StepSummary).exists()).toBe(true);
    });

    it('does not show the summary when this step is not finished', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(wrapper.findComponent(StepSummary).exists()).toBe(false);
    });
  });

  describe('Next button', () => {
    it('shows the next button when the text was passed', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(wrapper.text()).toBe('next');
    });

    it('does not show the next button when no text was passed', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({
        propsData: { nextStepButtonText: '' },
        apolloProvider: mockApollo,
      });

      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });

    it('is disabled when this step is not valid', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ propsData: { isValid: false }, apolloProvider: mockApollo });

      expect(wrapper.findComponent(GlButton).attributes('disabled')).toBe('true');
    });

    it('is enabled when this step is valid', () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ apolloProvider: mockApollo });

      expect(wrapper.findComponent(GlButton).attributes('disabled')).toBeUndefined();
    });

    it('displays an error if navigating too far', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 2);
      wrapper = createComponent({ propsData: { stepId: STEPS[2].id }, apolloProvider: mockApollo });

      wrapper.findComponent(GlButton).vm.$emit('click');
      await waitForPromises();

      expect(flash.mock.calls).toHaveLength(1);
      expect(flash.mock.calls[0][0]).toMatchObject({
        message: GENERAL_ERROR_MESSAGE,
        captureError: true,
        error: expect.any(Error),
      });
    });
  });

  describe('tracking', () => {
    it('emits stepEdit', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ propsData: { stepId: STEPS[1].id }, apolloProvider: mockApollo });

      // button in step-summary is not rendered b/c of shallowMount
      wrapper.vm.edit();

      await waitForPromises();
      expect(wrapper.emitted().stepEdit[0]).toEqual(['secondStep']);
    });

    it('emits nextStep on step transition', async () => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      wrapper = createComponent({ propsData: { stepId: STEPS[1].id }, apolloProvider: mockApollo });
      await activateFirstStep(mockApollo);

      wrapper.findComponent(GlButton).vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted().nextStep).toBeTruthy();
    });
  });
});
