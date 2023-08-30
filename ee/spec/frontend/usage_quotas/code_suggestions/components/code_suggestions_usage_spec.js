import { shallowMount } from '@vue/test-utils';
import CodeSuggestionsUsage from 'ee/usage_quotas/code_suggestions/components/code_suggestions_usage.vue';

describe('Code Suggestions Usage', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(CodeSuggestionsUsage);
  };

  describe('rendering', () => {
    it('renders code suggestions usage', () => {
      createComponent();

      expect(wrapper.findComponent(CodeSuggestionsUsage).exists()).toBe(true);
    });
  });
});
