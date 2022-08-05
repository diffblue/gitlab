import { cloneDeep } from 'lodash';
import ToolFilter from 'ee/security_dashboard/components/shared/filters/tool_filter.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FilterBody from 'ee/security_dashboard/components/shared/filters/filter_body.vue';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
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
  // More filter items to be added, hence using "findingAllComponents"
  // https://gitlab.com/gitlab-org/gitlab/-/issues/368255
  const findFilterItems = () => wrapper.findAllComponents(FilterItem);

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

  it('displays the all option item', () => {
    createWrapper();

    const { allOption } = filter;
    expect(findFilterItems().at(0).props('text')).toBe(allOption.name);
  });
});
