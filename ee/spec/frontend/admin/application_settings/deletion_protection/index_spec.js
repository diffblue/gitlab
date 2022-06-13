import Vue from 'vue';
import { initAdminDeletionProtectionSettings } from 'ee/admin/application_settings/deletion_protection';
import { parseFormProps } from 'ee/admin/application_settings/deletion_protection/utils';

jest.mock('ee/admin/application_settings/deletion_protection/utils', () => ({
  parseFormProps: jest.fn().mockReturnValue({
    deletionAdjournedPeriod: 7,
    delayedGroupDeletion: false,
    delayedProjectDeletion: false,
  }),
}));

describe('initAdminDeletionProtectionSettings', () => {
  let appRoot;

  const createAppRoot = () => {
    appRoot = document.createElement('div');
    appRoot.setAttribute('id', 'js-admin-deletion-protection-settings');
    appRoot.dataset.deletionAdjournedPeriod = 7;
    appRoot.dataset.delayedGroupDeletion = false;
    appRoot.dataset.delayedProjectDeletion = false;
    document.body.appendChild(appRoot);
  };

  afterEach(() => {
    if (appRoot) {
      appRoot.remove();
      appRoot = null;
    }
  });

  describe('when there is no app root', () => {
    it('returns false', () => {
      expect(initAdminDeletionProtectionSettings()).toBe(false);
    });
  });

  describe('when there is an app root', () => {
    beforeEach(() => {
      createAppRoot();
    });

    it('returns a Vue instance', () => {
      expect(initAdminDeletionProtectionSettings()).toBeInstanceOf(Vue);
    });

    it('parses the form props from the dataset', () => {
      initAdminDeletionProtectionSettings();

      expect(parseFormProps).toHaveBeenCalledWith(appRoot.dataset);
    });
  });
});
