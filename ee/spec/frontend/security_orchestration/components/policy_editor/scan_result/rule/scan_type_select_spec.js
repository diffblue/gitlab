import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_type_select.vue';
import {
  ANY_MERGE_REQUEST,
  LICENSE_FINDING,
  SCAN_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ScanTypeSelect', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ScanTypeSelect, {
      propsData: {
        ...props,
      },
      provide: {
        glFeatures: {
          scanResultAnyMergeRequest: true,
        },
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
    expect(findListBoxItems()).toHaveLength(3);
    expect(
      findListBox()
        .props('items')
        .map(({ value }) => value),
    ).toStrictEqual([ANY_MERGE_REQUEST, SCAN_FINDING, LICENSE_FINDING]);
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

    expect(findListBoxItems()).toHaveLength(1);
    expect(findListBoxItems().at(0).text('')).toEqual('test');
  });

  it('can preselect existing scan', () => {
    createComponent({
      scanType: LICENSE_FINDING,
    });

    expect(findListBox().props('selected')).toBe(LICENSE_FINDING);
  });
});
