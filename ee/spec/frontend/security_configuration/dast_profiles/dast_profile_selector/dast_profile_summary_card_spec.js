import { shallowMount } from '@vue/test-utils';
import DastProfileSummaryCard from 'ee/security_configuration/dast_profiles/dast_profile_selector/dast_profile_summary_card.vue';

describe('DastProfileSummaryCard', () => {
  let wrapper;

  const createFullComponent = (propsData) => {
    wrapper = shallowMount(DastProfileSummaryCard, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders properly', () => {
    createFullComponent({
      isEditable: true,
      allowSelection: true,
    });

    expect(wrapper.element).toMatchSnapshot();
  });
});
