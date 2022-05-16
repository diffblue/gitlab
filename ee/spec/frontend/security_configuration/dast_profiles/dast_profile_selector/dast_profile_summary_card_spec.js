import { GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DastProfileSummaryCard from 'ee/security_configuration/dast_profiles/dast_profile_selector/dast_profile_summary_card.vue';

const propsData = {
  isEditable: true,
  allowSelection: true,
};
describe('DastProfileSummaryCard', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(DastProfileSummaryCard, {
      propsData,
      stubs: { GlCard },
    });
  };

  const findProfileSelectBtn = () => wrapper.findByTestId('profile-select-btn');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders properly', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('emits correctly when a profile is selected', () => {
    findProfileSelectBtn().vm.$emit('click');
    expect(wrapper.emitted('select-profile')).toHaveLength(1);
  });
});
