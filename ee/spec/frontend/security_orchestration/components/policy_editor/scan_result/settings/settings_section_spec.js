import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SettingsSection from 'ee/security_orchestration/components/policy_editor/scan_result/settings/settings_section.vue';
import SettingsItem from 'ee/security_orchestration/components/policy_editor/scan_result/settings/settings_item.vue';

describe('SettingsSection', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(SettingsSection, {
      propsData,
      provide: {
        namespacePath: 'test-path',
      },
    });
  };

  const findAllSettingsItem = () => wrapper.findAllComponents(SettingsItem);
  const findProtectedBranchesSettingsItem = () =>
    wrapper.findByTestId('protected-branches-setting');
  const findMergeRequestSettingsItem = () => wrapper.findByTestId('merge-request-setting');

  describe('settings modification', () => {
    const createSettings = (value, key = 'block_protected_branch_modification') => ({
      settings: {
        [key]: {
          enabled: value,
        },
      },
    });

    it.each`
      description                                                   | propsData                                                            | protectedBranchSettingVisible | mergeRequestSettingVisible
      ${'disable block_protected_branch_modification setting'}      | ${createSettings(false)}                                             | ${true}                       | ${false}
      ${'enable block_protected_branch_modification setting'}       | ${createSettings(true)}                                              | ${true}                       | ${false}
      ${'disable prevent_approval_by_merge_request_author setting'} | ${createSettings(false, 'prevent_approval_by_merge_request_author')} | ${false}                      | ${true}
      ${'enable prevent_approval_by_merge_request_author setting'}  | ${createSettings(true, 'prevent_approval_by_merge_request_author')}  | ${false}                      | ${true}
    `(
      '$description',
      ({ propsData, protectedBranchSettingVisible, mergeRequestSettingVisible }) => {
        createComponent({ propsData });
        expect(findProtectedBranchesSettingsItem().exists()).toBe(protectedBranchSettingVisible);
        expect(findMergeRequestSettingsItem().exists()).toBe(mergeRequestSettingVisible);
        expect(findAllSettingsItem().at(0).props('settings')).toEqual(propsData.settings);
      },
    );

    it('emits event when setting is toggled', async () => {
      createComponent({ propsData: createSettings(true) });

      await findAllSettingsItem()
        .at(0)
        .vm.$emit('update', { key: 'block_protected_branch_modification', value: false });
      expect(wrapper.emitted('changed')).toEqual([[createSettings(false).settings]]);
    });

    it('should render different settings groups', () => {
      createComponent({
        propsData: {
          settings: {
            block_protected_branch_modification: {
              enabled: true,
            },
            prevent_approval_by_merge_request_author: {
              enabled: true,
            },
          },
        },
      });

      expect(findProtectedBranchesSettingsItem().exists()).toBe(true);
      expect(findMergeRequestSettingsItem().exists()).toBe(true);

      expect(findProtectedBranchesSettingsItem().props('link')).toBe(
        'http://test.host/test-path/-/settings/repository',
      );
      expect(findMergeRequestSettingsItem().props('link')).toBe(
        'http://test.host/test-path/-/settings/merge_requests',
      );
    });
  });
});
