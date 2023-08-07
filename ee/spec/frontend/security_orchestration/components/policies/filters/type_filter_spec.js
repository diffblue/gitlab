import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { POLICY_TYPE_FILTER_OPTIONS } from 'ee/security_orchestration/components/policies/constants';
import TypeFilter from 'ee/security_orchestration/components/policies/filters/type_filter.vue';

describe('TypeFilter component', () => {
  let wrapper;

  const createWrapper = (value = '') => {
    wrapper = shallowMount(TypeFilter, {
      propsData: {
        value,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  const findToggle = () => wrapper.findComponent(GlCollapsibleListbox);

  it.each`
    value                                                          | expectedToggleText
    ${POLICY_TYPE_FILTER_OPTIONS.ALL.value}                        | ${POLICY_TYPE_FILTER_OPTIONS.ALL.text}
    ${POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value} | ${POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.text}
  `('selects the correct option when value is "$value"', ({ value, expectedToggleText }) => {
    createWrapper(value);

    expect(findToggle().props('toggleText')).toBe(expectedToggleText);
  });

  it('displays the "All policies" option first', () => {
    createWrapper();

    expect(wrapper.findAllComponents(GlListboxItem).at(0).text()).toBe(
      POLICY_TYPE_FILTER_OPTIONS.ALL.text,
    );
  });

  it('emits an event when an option is selected', () => {
    createWrapper();

    expect(wrapper.emitted('input')).toBeUndefined();

    findToggle().vm.$emit('select', POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value);

    expect(wrapper.emitted('input')).toEqual([
      [POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value],
    ]);
  });
});
