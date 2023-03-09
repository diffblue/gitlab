import { shallowMount } from '@vue/test-utils';
import OnDemandScansProfileSummaryCell from 'ee/security_configuration/dast_profiles/dast_profile_selector/summary_cell.vue';

describe('DastProfileSummaryCell', () => {
  let wrapper;

  const createFullComponent = (propsData) => {
    wrapper = shallowMount(OnDemandScansProfileSummaryCell, {
      propsData,
    });
  };

  it('renders properly', () => {
    createFullComponent({
      label: 'Row Label',
      value: 'Row Value',
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders nothing when value prop is undefined', () => {
    createFullComponent({
      label: 'Row Label',
      value: undefined,
    });

    expect(wrapper.html()).toBe('');
  });
});
