import * as getters from 'ee/approvals/stores/modules/approval_settings/getters';

describe('Group settings store getters', () => {
  let settings;
  const initialSettings = {
    preventAuthorApproval: true,
    preventMrApprovalRuleEdit: true,
    requireUserPassword: true,
    removeApprovalsOnPush: true,
  };

  beforeEach(() => {
    settings = { ...initialSettings };
  });

  describe('settingChanged', () => {
    it('returns true when a setting is changed', () => {
      settings.preventAuthorApproval = false;

      expect(getters.settingChanged({ settings, initialSettings })).toBe(true);
    });

    it('returns false when the setting remains unchanged', () => {
      expect(getters.settingChanged({ settings, initialSettings })).toBe(false);
    });
  });
});
