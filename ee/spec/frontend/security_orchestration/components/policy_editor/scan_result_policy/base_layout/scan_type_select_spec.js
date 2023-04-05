import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/scan_type_select.vue';
import {
  LICENSE_FINDING,
  SCAN_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ScanTypeSelect', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ScanTypeSelect, {
      propsData: {
        ...props,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListBoxItems = () => findListBox().findAllComponents(GlListboxItem);

  it('can render defaultOptions', () => {
    createComponent();
    expect(findListBoxItems()).toHaveLength(2);
  });

  it('can select scan type', () => {
    createComponent();
    findListBox().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('select')).toEqual([[SCAN_FINDING]]);
  });

  it('can render additional options', () => {
    createComponent({
      items: [{ text: 'test', value: 'test' }],
    });

    expect(findListBoxItems()).toHaveLength(3);
    expect(findListBoxItems().at(0).text('')).toEqual('test');
  });

  it('can preselect existing scan', () => {
    createComponent({
      scanType: LICENSE_FINDING,
    });

    expect(findListBox().props('selected')).toBe(LICENSE_FINDING);
  });
});
