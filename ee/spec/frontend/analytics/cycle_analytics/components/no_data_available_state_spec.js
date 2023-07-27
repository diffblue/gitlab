import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NoDataAvailableState from 'ee/analytics/cycle_analytics/components/no_data_available_state.vue';
import {
  NO_DATA_AVAILABLE_TITLE,
  NO_DATA_AVAILABLE_DESCRIPTION,
} from 'ee/analytics/cycle_analytics/constants';

const CUSTOM_TITLE = 'Custom title';
const CUSTOM_DESCRIPTION = 'Custom description';

function createComponent({ props = {} } = {}) {
  return shallowMountExtended(NoDataAvailableState, {
    propsData: {
      ...props,
    },
  });
}

describe('NoDataAvailableState', () => {
  let wrapper;

  const findNoDataTitle = (_wrapper) => _wrapper.findByTestId('vsa-no-data-title');
  const findNoDataDescription = (_wrapper) => _wrapper.findByTestId('vsa-no-data-description');

  it('render default title and description', () => {
    wrapper = createComponent();

    expect(findNoDataTitle(wrapper).text()).toBe(NO_DATA_AVAILABLE_TITLE);
    expect(findNoDataDescription(wrapper).text()).toBe(NO_DATA_AVAILABLE_DESCRIPTION);
  });

  it('render custom title and description', () => {
    wrapper = createComponent({
      props: {
        title: CUSTOM_TITLE,
        description: CUSTOM_DESCRIPTION,
      },
    });

    expect(findNoDataTitle(wrapper).text()).toBe(CUSTOM_TITLE);
    expect(findNoDataDescription(wrapper).text()).toBe(CUSTOM_DESCRIPTION);
  });
});
