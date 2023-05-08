import { GlCollapsibleListbox, GlBadge } from '@gitlab/ui';
import BaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/base_layout_component.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/scan_filter_selector.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  SEVERITY,
  STATUS,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/constants';

describe('ScanFilterSelector', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ScanFilterSelector, {
      propsData: {
        ...props,
      },
      stubs: {
        BaseLayoutComponent,
        GlCollapsibleListbox,
      },
    });
  };

  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDisabledBadge = () => wrapper.findComponent(GlBadge);

  it.each([SEVERITY, STATUS])('should select filter', async ({ filter }) => {
    createComponent();

    await findListBox().vm.$emit('select', filter);

    expect(wrapper.emitted('select')).toEqual([[filter]]);
  });

  it.each`
    filter      | selected
    ${SEVERITY} | ${{ [SEVERITY]: [] }}
    ${STATUS}   | ${{ [NEWLY_DETECTED]: [], [PREVIOUSLY_EXISTING]: [] }}
  `('should disable selected filter and not emit events', async ({ filter, selected }) => {
    createComponent({ selected });

    expect(findDisabledBadge().exists()).toBe(true);

    await findListBox().vm.$emit('select', filter);

    expect(wrapper.emitted('select')).toBeUndefined();
  });

  it('can render custom options', () => {
    const customOption = { value: 'value', text: 'text' };
    createComponent({ items: [customOption] });

    expect(findListBox().props('items')).toEqual([customOption]);
  });

  it('can have disabled state', () => {
    createComponent({ disabled: true });
    expect(findListBox().props('disabled')).toBe(true);
  });

  it('can have custom tooltip text', () => {
    const tooltipTitle = 'Custom tooltip';
    createComponent({ tooltipTitle });
    expect(findListBox().attributes('title')).toBe(tooltipTitle);
  });
});
