import {
  PREVENT_APPROVAL_BY_MR_AUTHOR,
  buildSettingsList,
  mergeRequestConfiguration,
  protectedBranchesConfiguration,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/settings';

describe('approval_settings', () => {
  describe('buildSettingsList', () => {
    it('has defaults settings by default', () => {
      expect(buildSettingsList()).toEqual(protectedBranchesConfiguration);
    });

    it('has merge request settings by when flag is enabled', () => {
      expect(buildSettingsList({ hasAnyMergeRequestRule: true })).toEqual({
        ...protectedBranchesConfiguration,
        ...mergeRequestConfiguration,
      });
    });

    it('can update merge request settings', () => {
      mergeRequestConfiguration[PREVENT_APPROVAL_BY_MR_AUTHOR].enabled = true;
      expect(
        buildSettingsList({
          approvalSettings: mergeRequestConfiguration,
          hasAnyMergeRequestRule: true,
        }),
      ).toEqual({
        ...protectedBranchesConfiguration,
        ...mergeRequestConfiguration,
        [PREVENT_APPROVAL_BY_MR_AUTHOR]: {
          enabled: true,
        },
      });
    });

    it('has fall back values for approval settings', () => {
      const newOption = {
        [PREVENT_APPROVAL_BY_MR_AUTHOR]: undefined,
      };

      const settings = {
        ...mergeRequestConfiguration,
        ...newOption,
      };

      expect(
        buildSettingsList({ approvalSettings: settings, hasAnyMergeRequestRule: true }),
      ).toEqual({
        ...protectedBranchesConfiguration,
        ...mergeRequestConfiguration,
      });
    });
  });
});
