import { GlListboxItem, GlCollapsibleListbox } from '@gitlab/ui';
import { POLICY_SOURCE_OPTIONS } from 'ee/security_orchestration/components/policies/constants';
import SourceFilter from 'ee/security_orchestration/components/policies/filters/source_filter.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('SourceFilter component', () => {
  let wrapper;

  const createWrapper = (value = POLICY_SOURCE_OPTIONS.ALL.value) => {
    wrapper = mountExtended(SourceFilter, {
      propsData: {
        value,
      },
    });
  };

  const findToggle = () => wrapper.findComponent(GlCollapsibleListbox);

  it.each`
    value                                    | expectedToggleText
    ${POLICY_SOURCE_OPTIONS.ALL.value}       | ${POLICY_SOURCE_OPTIONS.ALL.text}
    ${POLICY_SOURCE_OPTIONS.DIRECT.value}    | ${POLICY_SOURCE_OPTIONS.DIRECT.text}
    ${POLICY_SOURCE_OPTIONS.INHERITED.value} | ${POLICY_SOURCE_OPTIONS.INHERITED.text}
  `('selects the correct option when value is "$value"', ({ value, expectedToggleText }) => {
    createWrapper(value);

    expect(findToggle().props('toggleText')).toBe(expectedToggleText);
  });

  it('displays the "All policies" option first', () => {
    createWrapper();

    expect(wrapper.findAllComponents(GlListboxItem).at(0).text()).toBe(
      POLICY_SOURCE_OPTIONS.ALL.text,
    );
  });

  it('emits an event when an option is selected', () => {
    createWrapper();

    expect(wrapper.emitted('input')).toBeUndefined();

    wrapper
      .findByTestId(`policy-source-${POLICY_SOURCE_OPTIONS.INHERITED.value}-option`)
      .trigger('click');

    expect(wrapper.emitted('input')).toEqual([[POLICY_SOURCE_OPTIONS.INHERITED.value]]);
  });
});
