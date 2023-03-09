import { shallowMount } from '@vue/test-utils';
import DastProfileSelectorEmptyState from 'ee/security_configuration/dast_profiles/dast_profile_selector/empty_state.vue';

describe('DastProfileSelectorEmptyState', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(DastProfileSelectorEmptyState, {
      slots: {
        header: 'heading',
        content: 'content',
      },
    });
  };

  it('renders properly', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });
});
