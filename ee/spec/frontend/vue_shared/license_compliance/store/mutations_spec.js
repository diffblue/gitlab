import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';
import createStore from 'ee/vue_shared/license_compliance/store';
import * as types from 'ee/vue_shared/license_compliance/store/mutation_types';

import { TEST_HOST } from 'spec/test_constants';
import { allowedLicense } from '../mock_data';

describe('License store mutations', () => {
  let store;

  beforeEach(() => {
    store = createStore();
  });

  describe('SET_LICENSE_IN_MODAL', () => {
    it('opens modal and sets passed license', () => {
      store.commit(`licenseManagement/${types.SET_LICENSE_IN_MODAL}`, allowedLicense);

      expect(store.state.licenseManagement.currentLicenseInModal).toBe(allowedLicense);
    });
  });

  describe('SET_KNOWN_LICENSES', () => {
    it('assigns knownLicenses to the store', () => {
      const licenses = [{ name: 'BSD' }, { name: 'Apache' }];
      store.commit(`licenseManagement/${types.SET_KNOWN_LICENSES}`, licenses);

      expect(store.state.licenseManagement.knownLicenses).toBe(licenses);
    });
  });

  describe('RESET_LICENSE_IN_MODAL', () => {
    it('closes modal and deletes licenseInApproval', () => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          currentLicenseInModal: allowedLicense,
        },
      });

      store.commit(`licenseManagement/${types.RESET_LICENSE_IN_MODAL}`);

      expect(store.state.licenseManagement.currentLicenseInModal).toBeNull();
    });
  });

  describe('SET_API_SETTINGS', () => {
    it('assigns data to the store', () => {
      const data = { apiUrlManageLicenses: TEST_HOST };

      store.commit(`licenseManagement/${types.SET_API_SETTINGS}`, data);

      expect(store.state.licenseManagement.apiUrlManageLicenses).toBe(TEST_HOST);
    });
  });

  describe('SET_IS_ADMIN', () => {
    it('sets isAdmin to false', () => {
      store.commit(`licenseManagement/${types.SET_IS_ADMIN}`, false);

      expect(store.state.licenseManagement.isAdmin).toBe(false);
    });

    it('sets isAdmin to true', () => {
      store.commit(`licenseManagement/${types.SET_IS_ADMIN}`, true);

      expect(store.state.licenseManagement.isAdmin).toBe(true);
    });
  });

  describe('REQUEST_LICENSE_CHECK_APPROVAL_RULE', () => {
    it('sets isLoadingLicenseCheckApprovalRule to true', () => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          isLoadingLicenseCheckApprovalRule: true,
        },
      });

      store.commit(`licenseManagement/${types.REQUEST_LICENSE_CHECK_APPROVAL_RULE}`);

      expect(store.state.licenseManagement.isLoadingLicenseCheckApprovalRule).toBe(true);
    });
  });

  describe('RECEIVE_LICENSE_CHECK_APPROVAL_RULE_SUCCESS', () => {
    it('sets isLoadingLicenseCheckApprovalRule to false and hasLicenseCheckApprovalRule to true', () => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          isLoadingLicenseCheckApprovalRule: true,
        },
      });

      store.commit(`licenseManagement/${types.RECEIVE_LICENSE_CHECK_APPROVAL_RULE_SUCCESS}`, {
        hasLicenseCheckApprovalRule: true,
      });

      expect(store.state.licenseManagement.isLoadingLicenseCheckApprovalRule).toBe(false);
      expect(store.state.licenseManagement.hasLicenseCheckApprovalRule).toBe(true);
    });
  });

  describe('RECEIVE_LICENSE_CHECK_APPROVAL_RULE_ERROR', () => {
    it('sets isLoadingLicenseCheckApprovalRule to false', () => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          isLoadingLicenseCheckApprovalRule: true,
        },
      });

      store.commit(`licenseManagement/${types.RECEIVE_LICENSE_CHECK_APPROVAL_RULE_ERROR}`);

      expect(store.state.licenseManagement.isLoadingLicenseCheckApprovalRule).toBe(false);
    });
  });

  describe('RECEIVE_MANAGED_LICENSES_SUCCESS', () => {
    it('sets isLoadingManagedLicenses to false and saves managed licenses', () => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          managedLicenses: false,
          isLoadingManagedLicenses: true,
        },
      });

      store.commit(`licenseManagement/${types.RECEIVE_MANAGED_LICENSES_SUCCESS}`, [
        { name: 'Foo', approval_status: LICENSE_APPROVAL_STATUS.approved },
      ]);

      expect(store.state.licenseManagement.managedLicenses).toEqual([
        { name: 'Foo', approvalStatus: LICENSE_APPROVAL_STATUS.approved },
      ]);

      expect(store.state.licenseManagement.isLoadingManagedLicenses).toBe(false);
    });
  });

  describe('RECEIVE_MANAGED_LICENSES_ERROR', () => {
    it('sets isLoadingManagedLicenses to true and saves the error', () => {
      const error = new Error('test');
      store.replaceState({
        ...store.state,
        licenseManagement: {
          isLoadingManagedLicenses: true,
        },
      });

      store.commit(`licenseManagement/${types.RECEIVE_MANAGED_LICENSES_ERROR}`, error);

      expect(store.state.licenseManagement.isLoadingManagedLicenses).toBe(false);
    });
  });

  describe('REQUEST_MANAGED_LICENSES', () => {
    it('sets isLoadingManagedLicenses to true', () => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          isLoadingManagedLicenses: true,
        },
      });

      store.commit(`licenseManagement/${types.REQUEST_MANAGED_LICENSES}`);

      expect(store.state.licenseManagement.isLoadingManagedLicenses).toBe(true);
    });
  });

  describe('REQUEST_PARSED_LICENSE_REPORT', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          isLoadingLicenseReport: false,
        },
      });
      store.commit(`licenseManagement/${types.REQUEST_PARSED_LICENSE_REPORT}`);
    });

    it('should initiate loading', () => {
      expect(store.state.licenseManagement.isLoadingLicenseReport).toBe(true);
    });
  });

  describe('RECEIVE_PARSED_LICENSE_REPORT_SUCCESS', () => {
    const newLicenses = [];
    const existingLicenses = [];

    beforeEach(() => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          isLoadingLicenseReport: true,
          loadLicenseReportError: new Error('test'),
        },
      });
      store.commit(`licenseManagement/${types.RECEIVE_PARSED_LICENSE_REPORT_SUCCESS}`, {
        newLicenses,
        existingLicenses,
      });
    });

    it('should set the new and existing reports', () => {
      expect(store.state.licenseManagement.newLicenses).toBe(newLicenses);
      expect(store.state.licenseManagement.existingLicenses).toBe(existingLicenses);
    });

    it('should cancel loading and clear any errors', () => {
      expect(store.state.licenseManagement.isLoadingLicenseReport).toBe(false);
      expect(store.state.licenseManagement.loadLicenseReportError).toBe(false);
    });
  });

  describe('RECEIVE_PARSED_LICENSE_REPORT_ERROR', () => {
    const error = new Error('test');
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          isLoadingLicenseReport: true,
          loadLicenseReportError: false,
        },
      });
      store.commit(`licenseManagement/${types.RECEIVE_PARSED_LICENSE_REPORT_ERROR}`, error);
    });

    it('should set the error on the state', () => {
      expect(store.state.licenseManagement.loadLicenseReportError).toBe(error);
    });

    it('should cancel loading', () => {
      expect(store.state.licenseManagement.isLoadingLicenseReport).toBe(false);
    });
  });

  describe('ADD_PENDING_LICENSE', () => {
    it('appends given id to pendingLicenses', () => {
      store.commit(`licenseManagement/${types.ADD_PENDING_LICENSE}`, 5);
      expect(store.state.licenseManagement.pendingLicenses).toEqual([5]);
      store.commit(`licenseManagement/${types.ADD_PENDING_LICENSE}`, null);
      expect(store.state.licenseManagement.pendingLicenses).toEqual([5, null]);
    });
  });

  describe('REMOVE_PENDING_LICENSE', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        licenseManagement: {
          pendingLicenses: [5, null],
        },
      });
    });

    it('appends given id to pendingLicenses', () => {
      store.commit(`licenseManagement/${types.REMOVE_PENDING_LICENSE}`, null);
      expect(store.state.licenseManagement.pendingLicenses).toEqual([5]);
      store.commit(`licenseManagement/${types.REMOVE_PENDING_LICENSE}`, 5);
      expect(store.state.licenseManagement.pendingLicenses).toEqual([]);
    });
  });
});
