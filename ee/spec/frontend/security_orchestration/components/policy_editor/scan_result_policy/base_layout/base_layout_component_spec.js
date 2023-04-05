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

  const findBaseLayoutLabel = () => wrapper.findByTestId('base-label');
  const findRemoveButton = () => wrapper.findByTestId('remove-rule');
  const findScannerTypeSelector = () => wrapper.findComponent(ScanTypeSelect);

  it('displays label and remove button by default', () => {
    expect(findBaseLayoutLabel().exists()).toBe(true);
    expect(findRemoveButton().exists()).toBe(true);
  });

  it('removes base layout', () => {
    findRemoveButton().vm.$emit('click');
    expect(wrapper.emitted('remove')).toHaveLength(1);
  });

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

  describe('layout configuration', () => {
    it('can hide label and remove button', () => {
      createComponent({
        showRemoveButton: false,
      });

      expect(findBaseLayoutLabel().exists()).toBe(false);
      expect(findRemoveButton().exists()).toBe(false);
    });
  });
});
