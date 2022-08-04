import { cloneDeep } from 'lodash';
import * as getters from 'ee/approvals/stores/modules/approval_settings/getters';

describe('Group settings store getters', () => {
  let settings;
  const initialSettings = {
    preventAuthorApproval: { value: true },
    preventCommittersApproval: { value: true },
    preventMrApprovalRuleEdit: { value: true },
    requireUserPassword: { value: true },
    removeApprovalsOnPush: { value: false },
    selectiveCodeOwnerRemovals: { value: false },
  };

  beforeEach(() => {
    settings = cloneDeep(initialSettings);
  });

  describe('settingChanged', () => {
    it('returns true when a setting is changed', () => {
      settings.preventAuthorApproval.value = false;

      expect(getters.settingChanged({ settings, initialSettings })).toBe(true);
    });

    it('returns false when the setting remains unchanged', () => {
      expect(getters.settingChanged({ settings, initialSettings })).toBe(false);
    });
  });
});
