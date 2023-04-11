import { GlCollapsibleListbox, GlBadge } from '@gitlab/ui';
import BaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/base_layout_component.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/scan_filter_selector.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  SEVERITY,
  STATUS,
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

  it.each([SEVERITY, STATUS])(
    'should disable selected filter and not emit events',
    async (filter) => {
      createComponent({ selected: [filter] });

      expect(findDisabledBadge().exists()).toBe(true);

      await findListBox().vm.$emit('select', filter);

      expect(wrapper.emitted('select')).toBeUndefined();
    },
  );
});
