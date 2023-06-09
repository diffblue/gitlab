import BaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/base_layout_component.vue';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/scan_type_select.vue';
import {
  getDefaultRule,
  SCAN_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('BaseLayoutComponent', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BaseLayoutComponent, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent({ ruleLabel: 'ruleLabel' });
  });

  const findScannerTypeSelector = () => wrapper.findComponent(ScanTypeSelect);

  describe('type selector', () => {
    beforeEach(() => {
      createComponent({ showScanTypeDropdown: true });
    });

    it('can render type selector', () => {
      expect(findScannerTypeSelector().exists()).toBe(true);
    });

    it('can select scan type', () => {
      findScannerTypeSelector().vm.$emit('select', SCAN_FINDING);
      expect(wrapper.emitted('changed')).toEqual([[getDefaultRule(SCAN_FINDING)]]);
    });
  });
});
