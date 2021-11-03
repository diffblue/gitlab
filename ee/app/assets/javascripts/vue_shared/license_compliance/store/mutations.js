import * as types from './mutation_types';
import { normalizeLicense } from './utils';

export default {
  [types.SET_LICENSE_IN_MODAL](state, license) {
    Object.assign(state, {
      currentLicenseInModal: license,
    });
  },
  [types.RESET_LICENSE_IN_MODAL](state) {
    Object.assign(state, {
      currentLicenseInModal: null,
    });
  },
  [types.SET_API_SETTINGS](state, data) {
    Object.assign(state, data);
  },
  [types.SET_IS_ADMIN](state, data) {
    Object.assign(state, {
      isAdmin: data,
    });
  },
  [types.SET_KNOWN_LICENSES](state, data) {
    Object.assign(state, {
      knownLicenses: data,
    });
  },
  [types.RECEIVE_MANAGED_LICENSES_SUCCESS](state, licenses = []) {
    const managedLicenses = licenses.map(normalizeLicense).reverse();

    Object.assign(state, {
      managedLicenses,
      isLoadingManagedLicenses: false,
    });
  },
  [types.RECEIVE_MANAGED_LICENSES_ERROR](state) {
    Object.assign(state, {
      managedLicenses: [],
      isLoadingManagedLicenses: false,
    });
  },
  [types.REQUEST_MANAGED_LICENSES](state) {
    Object.assign(state, {
      isLoadingManagedLicenses: true,
    });
  },

  [types.RECEIVE_PARSED_LICENSE_REPORT_SUCCESS](state, { newLicenses, existingLicenses }) {
    Object.assign(state, {
      newLicenses,
      existingLicenses,
      isLoadingLicenseReport: false,
      loadLicenseReportError: false,
    });
  },
  [types.RECEIVE_PARSED_LICENSE_REPORT_ERROR](state, error) {
    Object.assign(state, {
      isLoadingLicenseReport: false,
      loadLicenseReportError: error,
    });
  },
  [types.REQUEST_PARSED_LICENSE_REPORT](state) {
    Object.assign(state, {
      isLoadingLicenseReport: true,
    });
  },
  [types.REQUEST_LICENSE_CHECK_APPROVAL_RULE](state) {
    Object.assign(state, {
      isLoadingLicenseCheckApprovalRule: true,
    });
  },
  [types.RECEIVE_LICENSE_CHECK_APPROVAL_RULE_SUCCESS](state, { hasLicenseCheckApprovalRule }) {
    Object.assign(state, {
      isLoadingLicenseCheckApprovalRule: false,
      hasLicenseCheckApprovalRule,
    });
  },
  [types.RECEIVE_LICENSE_CHECK_APPROVAL_RULE_ERROR](state) {
    Object.assign(state, {
      isLoadingLicenseCheckApprovalRule: false,
    });
  },
  [types.ADD_PENDING_LICENSE](state, id) {
    state.pendingLicenses.push(id);
  },
  [types.REMOVE_PENDING_LICENSE](state, id) {
    state.pendingLicenses = state.pendingLicenses.filter((pendingLicense) => pendingLicense !== id);
  },
};
