import { GlDropdownItem } from '@gitlab/ui';
import { POLICY_TYPE_FILTER_OPTIONS } from 'ee/security_orchestration/components/policies/constants';
import PolicyTypeFilter from 'ee/security_orchestration/components/policies/filters/policy_type_filter.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('PolicyTypeFilter component', () => {
  let wrapper;

  const createWrapper = (value = '') => {
    wrapper = mountExtended(PolicyTypeFilter, {
      propsData: {
        value,
      },
    });
  };

  const findToggle = () => wrapper.find('button[aria-haspopup="menu"]');

  it.each`
    value                                                          | expectedToggleText
    ${POLICY_TYPE_FILTER_OPTIONS.ALL.value}                        | ${POLICY_TYPE_FILTER_OPTIONS.ALL.text}
    ${POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value} | ${POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.text}
  `('selects the correct option when value is "$value"', ({ value, expectedToggleText }) => {
    createWrapper(value);

    expect(findToggle().text()).toBe(expectedToggleText);
  });

  it('displays the "All policies" option first', () => {
    createWrapper();

    expect(wrapper.findAllComponents(GlDropdownItem).at(0).text()).toBe(
      POLICY_TYPE_FILTER_OPTIONS.ALL.text,
    );
  });

  it('emits an event when an option is selected', () => {
    createWrapper();

    expect(wrapper.emitted('input')).toBeUndefined();

    wrapper
      .findByTestId(
        `policy-type-${POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value}-option`,
      )
      .trigger('click');

    expect(wrapper.emitted('input')).toEqual([
      [POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value],
    ]);
  });
});
