import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import BranchDropdownFilter from 'ee/compliance_dashboard/components/violations_report/violations/branch_dropdown_filter.vue';
import { BRANCH_FILTER_OPTIONS } from 'ee/compliance_dashboard/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('BranchDropdownFilter component', () => {
  const OPTION_VALUES = Object.values(BRANCH_FILTER_OPTIONS);

  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItem = (idx) => findDropdownItems().at(idx);
  const findCheckedOptions = () => findDropdownItems().filter((item) => item.props().isChecked);

  const isOnlyCheckedOption = (value) => {
    expect(findCheckedOptions()).toHaveLength(1);
    expect(findCheckedOptions().at(0).text()).toBe(value);
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BranchDropdownFilter, {
      propsData: {
        ...props,
      },
    });
  };

  describe('default behavior', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it.each(Object.keys(OPTION_VALUES))('renders the expected dropdown item at %s', (idx) => {
      expect(findDropdownItem(idx).text()).toBe(OPTION_VALUES[idx]);
    });

    it('renders the first branch option as the selected option', () => {
      expect(findDropdown().props('text')).toBe(OPTION_VALUES[0]);
      expect(findDropdownItem(0).props('isChecked')).toBe(true);
    });

    it('selects a new branch when another option is clicked', async () => {
      const newValue = OPTION_VALUES[1];

      await findDropdownItem(1).vm.$emit('click');

      expect(wrapper.emitted('selected')).toStrictEqual([[newValue]]);
      expect(findDropdown().props('text')).toBe(newValue);
      isOnlyCheckedOption(newValue);
    });
  });

  describe('when provided with a default branch value', () => {
    const defaultBranch = OPTION_VALUES[1];

    beforeEach(() => {
      createComponent({ defaultBranch });
    });

    it('renders the provided default branch as the selected option', () => {
      expect(findDropdown().props('text')).toBe(defaultBranch);
      isOnlyCheckedOption(defaultBranch);
    });
  });
});
