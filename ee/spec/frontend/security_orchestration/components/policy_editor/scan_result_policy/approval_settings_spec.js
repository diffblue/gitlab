import { GlFormCheckbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ApprovalSettings from 'ee/security_orchestration/components/policy_editor/scan_result_policy/approval_settings.vue';

describe('ApprovalSettings', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(ApprovalSettings, {
      propsData,
    });
  };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  describe('"block_unprotecting_branches" checkbox', () => {
    const createSettings = (value) => ({
      approvalSettings: {
        block_unprotecting_branches: {
          enabled: value,
        },
      },
    });

    it.each`
      title                                | propsData                | expected
      ${'unchecked by default'}            | ${{}}                    | ${undefined}
      ${'unchecked when enabled is false'} | ${createSettings(false)} | ${undefined}
      ${'checked when enabled is true'}    | ${createSettings(true)}  | ${'true'}
    `('renders setting checkbox as $title', ({ propsData, expected }) => {
      createComponent(propsData);
      expect(findCheckbox().attributes('checked')).toBe(expected);
    });

    it('emits event when checkbox is clicked', async () => {
      createComponent();
      await findCheckbox().vm.$emit('change', true);
      expect(wrapper.emitted('changed')).toEqual([[createSettings(true).approvalSettings]]);
    });
  });
});
