import { cloneDeep } from 'lodash';
import ToolFilter from 'ee/security_dashboard/components/shared/filters/tool_filter.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FilterBody from 'ee/security_dashboard/components/shared/filters/filter_body.vue';
import { vendorScannerFilter } from 'ee/security_dashboard/helpers';

describe('Tool Filter component', () => {
  let wrapper;
  let filter;

  const createWrapper = () => {
    filter = cloneDeep(vendorScannerFilter);

    wrapper = shallowMountExtended(ToolFilter, {
      propsData: { filter },
    });
  };

  const findFilterBody = () => wrapper.findComponent(FilterBody);

  afterEach(() => {
    wrapper.destroy();
  });

  it('provides the correct props to the FilterBody component', () => {
    createWrapper();

    const { name, allOption } = filter;
    expect(findFilterBody().props()).toMatchObject({
      name,
      selectedOptions: [allOption],
    });
  });
});
