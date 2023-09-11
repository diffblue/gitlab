import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import CodeSuggestionsIntro from 'ee/usage_quotas/code_suggestions/components/code_suggestions_intro.vue';
import { salesLink } from 'ee/usage_quotas/code_suggestions/constants';

describe('Code Suggestions Intro', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(CodeSuggestionsIntro, { mocks: { GlEmptyState } });
  };

  describe('when rendering', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('renders gl-empty-state component', () => {
      const emptyState = wrapper.findComponent(GlEmptyState);

      expect(emptyState.exists()).toBe(true);
      expect(emptyState.props('primaryButtonLink')).toBe(salesLink);
      expect(emptyState.props('primaryButtonText')).toBe('Contact sales');
    });
  });
});
