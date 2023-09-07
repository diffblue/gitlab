import { GlFormCheckbox, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SettingsSection from 'ee/security_orchestration/components/policy_editor/scan_result_policy/settings_section.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

jest.mock('~/lib/utils/url_utility', () => {
  return {
    getBaseURL: jest.fn().mockReturnValue('http://gitlab.local/'),
    ...jest.requireActual('~/lib/utils/url_utility'),
  };
});

describe('SettingsSection', () => {
  let wrapper;
  const namespacePath = 'path/to/project';

  const createComponent = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(SettingsSection, {
      propsData,
      provide: {
        namespaceType: NAMESPACE_TYPES.PROJECT,
        namespacePath,
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findProtectedBranchesSettingSubHeaderProjectLink = () =>
    wrapper.findByTestId('protected-branches-settings-project-link');
  const findProtectedBranchesSettingSubHeaderGroupText = () =>
    wrapper.findByTestId('protected-branches-settings-group-text');
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  describe('sub-header', () => {
    it('renders the link on the project level', () => {
      createComponent({});
      expect(findProtectedBranchesSettingSubHeaderProjectLink().exists()).toBe(true);
      expect(findProtectedBranchesSettingSubHeaderProjectLink().attributes('href')).toBe(
        'http://test.host/path/to/project/-/settings/repository',
      );
      expect(findProtectedBranchesSettingSubHeaderGroupText().exists()).toBe(false);
    });

    it('does not render the link on the group level', () => {
      createComponent({ provide: { namespaceType: NAMESPACE_TYPES.GROUP } });
      expect(findProtectedBranchesSettingSubHeaderProjectLink().exists()).toBe(false);
      expect(findProtectedBranchesSettingSubHeaderGroupText().exists()).toBe(true);
    });
  });

  describe('protected branches settings', () => {
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
        ${'unchecked by default'}            | ${{}}                    | ${undefined}
        ${'unchecked when enabled is false'} | ${createSettings(false)} | ${undefined}
        ${'checked when enabled is true'}    | ${createSettings(true)}  | ${'true'}
      `('renders setting checkbox as $title', ({ propsData, expected }) => {
        createComponent({ propsData });
        expect(findCheckbox().attributes('checked')).toBe(expected);
      });

      it('emits event when checkbox is clicked', async () => {
        createComponent();
        await findCheckbox().vm.$emit('change', true);
        expect(wrapper.emitted('changed')).toEqual([[createSettings(true).settings]]);
      });
    });
  });
});
