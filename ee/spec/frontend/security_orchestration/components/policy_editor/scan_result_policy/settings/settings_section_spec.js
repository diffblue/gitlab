import { GlFormCheckbox, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SettingsSection from 'ee/security_orchestration/components/policy_editor/scan_result_policy/settings/settings_section.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('ApprovalSettings', () => {
  let wrapper;

  const createComponent = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(SettingsSection, {
      propsData,
      provide: {
        namespaceType: NAMESPACE_TYPES.PROJECT,
        namespacePath: 'test-path',
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findDescriptionText = () => wrapper.findByTestId('protected-branches-settings-group-text');
  const findDescriptionLink = () => wrapper.findComponent(GlLink);

  describe('"block_protected_branch_modification" checkbox', () => {
    const createSettings = (value) => ({
      settings: {
        block_protected_branch_modification: {
          enabled: value,
        },
      },
    });

    it.each`
      title                                | propsData                | expected
      ${'unchecked when enabled is false'} | ${createSettings(false)} | ${undefined}
      ${'checked when enabled is true'}    | ${createSettings(true)}  | ${'true'}
    `('renders setting checkbox as $title', ({ propsData, expected }) => {
      createComponent({ propsData });
      expect(findCheckbox().attributes('checked')).toBe(expected);
    });

    it('emits event when checkbox is clicked', async () => {
      createComponent({ propsData: createSettings(true) });

      await findCheckbox().vm.$emit('change', true);
      expect(wrapper.emitted('changed')).toEqual([[createSettings(true).settings]]);
    });

    it('should render link for project', () => {
      createComponent({ provide: { namespaceType: NAMESPACE_TYPES.PROJECT } });

      expect(findDescriptionLink().exists()).toBe(true);
      expect(findDescriptionText().exists()).toBe(false);
    });

    it('should render text for group', () => {
      createComponent({ provide: { namespaceType: NAMESPACE_TYPES.GROUP } });

      expect(findDescriptionLink().exists()).toBe(false);
      expect(findDescriptionText().exists()).toBe(true);
    });
  });
});
