import { shallowMount } from '@vue/test-utils';
import OnDemandScansProfileSummaryCell from 'ee/on_demand_scans_form/components/profile_selector/summary_cell.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('OnDemandScansProfileSummaryCell', () => {
  let wrapper;

  const createFullComponent = (propsData) => {
    wrapper = extendedWrapper(
      shallowMount(OnDemandScansProfileSummaryCell, {
        propsData,
      }),
    );
  };

  const findValue = () => wrapper.findByTestId('summary-value');

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

  it('renders default when value prop is undefined', () => {
    createFullComponent({
      label: 'Row Label',
      value: undefined,
    });

    expect(findValue().text()).toContain('None');
  });
});
