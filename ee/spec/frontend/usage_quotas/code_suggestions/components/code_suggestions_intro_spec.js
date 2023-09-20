import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import CodeSuggestionsIntro from 'ee/usage_quotas/code_suggestions/components/code_suggestions_intro.vue';
import { salesLink } from 'ee/usage_quotas/code_suggestions/constants';
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';

describe('Code Suggestions Intro', () => {
  let wrapper;
  const emptyState = () => wrapper.findComponent(GlEmptyState);
  const handRaiseLeadButton = () => wrapper.findComponent(HandRaiseLeadButton);

  const createComponent = (createHandRaiseLeadPath) => {
    wrapper = shallowMount(CodeSuggestionsIntro, {
      mocks: { GlEmptyState },
      provide: { createHandRaiseLeadPath },
    });
  };

  describe('when rendering', () => {
    describe('when not showing hand raise lead button', () => {
      beforeEach(() => {
        return createComponent();
      });

      it('renders gl-empty-state component', () => {
        expect(emptyState().exists()).toBe(true);
        expect(emptyState().props('primaryButtonLink')).toBe(salesLink);
        expect(emptyState().props('primaryButtonText')).toBe('Contact sales');
        expect(handRaiseLeadButton().exists()).toBe(false);
      });
    });

    describe('when showing hand raise lead button', () => {
      beforeEach(() => {
        return createComponent('some-path');
      });

      it('renders gl-empty-state component without default button, but with hand raise lead button', () => {
        const defaultButton = wrapper.find(`a[href="${salesLink}"`);
        expect(emptyState().exists()).toBe(true);
        expect(handRaiseLeadButton().exists()).toBe(true);
        expect(defaultButton.exists()).toBe(false);
      });
    });
  });
});
