import { shallowMount } from '@vue/test-utils';
import OnDemandScansProfileSummaryCell from 'ee/on_demand_scans_form/components/profile_selector/summary_cell.vue';

describe('OnDemandScansProfileSummaryCell', () => {
  let wrapper;

  const createFullComponent = (propsData) => {
    wrapper = shallowMount(OnDemandScansProfileSummaryCell, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
