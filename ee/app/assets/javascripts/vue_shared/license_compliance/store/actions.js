import { LICENSE_CHECK_NAME } from 'ee/approvals/constants';
import axios from '~/lib/utils/axios_utils';
import pollUntilComplete from '~/lib/utils/poll_until_complete';
import { LICENSE_LIST } from 'ee/license_compliance/store/constants';
import { LICENSE_APPROVAL_STATUS } from '../constants';
import * as types from './mutation_types';
import { convertToOldReportFormat } from './utils';

export const setAPISettings = ({ commit }, data) => {
  commit(types.SET_API_SETTINGS, data);
};

export const setLicenseInModal = ({ commit }, license) => {
  commit(types.SET_LICENSE_IN_MODAL, license);
};

export const setIsAdmin = ({ commit }, payload) => {
  commit(types.SET_IS_ADMIN, payload);
};

export const setKnownLicenses = ({ commit }, licenses) => {
  commit(types.SET_KNOWN_LICENSES, licenses);
};

export const resetLicenseInModal = ({ commit }) => {
  commit(types.RESET_LICENSE_IN_MODAL);
};

export const receiveDeleteLicense = ({ commit, dispatch }, id) => {
  commit(types.RESET_LICENSE_IN_MODAL);
  dispatch(`${LICENSE_LIST}/fetchLicenses`, null, { root: true });
  return dispatch('fetchManagedLicenses').then(() => {
    dispatch('removePendingLicense', id);
  });
};
export const receiveDeleteLicenseError = ({ commit }) => {
  commit(types.RESET_LICENSE_IN_MODAL);
};
export const deleteLicense = ({ dispatch, state }) => {
  const licenseId = state.currentLicenseInModal.id;
  dispatch('addPendingLicense', licenseId);
  const endpoint = `${state.apiUrlManageLicenses}/${licenseId}`;
  return axios
    .delete(endpoint)
    .then(() => {
      dispatch('receiveDeleteLicense', licenseId);
    })
    .catch(() => {
      dispatch('receiveDeleteLicenseError');
      dispatch('removePendingLicense', licenseId);
    });
};

export const requestManagedLicenses = ({ commit }) => {
  commit(types.REQUEST_MANAGED_LICENSES);
};
export const receiveManagedLicensesSuccess = ({ commit }, licenses) => {
  commit(types.RECEIVE_MANAGED_LICENSES_SUCCESS, licenses);
};
export const receiveManagedLicensesError = ({ commit }) => {
  commit(types.RECEIVE_MANAGED_LICENSES_ERROR);
};
export const fetchManagedLicenses = ({ dispatch, state }) => {
  dispatch('requestManagedLicenses');

  const { apiUrlManageLicenses } = state;

  return axios
    .get(apiUrlManageLicenses, { params: { per_page: 100 } })
    .then(({ data }) => {
      dispatch('receiveManagedLicensesSuccess', data);
    })
    .catch(() => {
      dispatch('receiveManagedLicensesError');
    });
};

export const requestParsedLicenseReport = ({ commit }) => {
  commit(types.REQUEST_PARSED_LICENSE_REPORT);
};
export const receiveParsedLicenseReportSuccess = ({ commit }, reports) => {
  commit(types.RECEIVE_PARSED_LICENSE_REPORT_SUCCESS, reports);
};
export const receiveParsedLicenseReportError = ({ commit }, error) => {
  commit(types.RECEIVE_PARSED_LICENSE_REPORT_ERROR, error);
};
export const fetchParsedLicenseReport = ({ dispatch, state }) => {
  dispatch('requestParsedLicenseReport');

  pollUntilComplete(state.licensesApiPath)
    .then(({ data }) => {
      const newLicenses = (data.new_licenses || data).map(convertToOldReportFormat);
      const existingLicenses = (data.existing_licenses || []).map(convertToOldReportFormat);
      dispatch('receiveParsedLicenseReportSuccess', { newLicenses, existingLicenses });
    })
    .catch((error) => {
      dispatch('receiveParsedLicenseReportError', error);
    });
};

export const receiveSetLicenseApproval = ({ commit, dispatch, state }, id) => {
  commit(types.RESET_LICENSE_IN_MODAL);
  dispatch(`${LICENSE_LIST}/fetchLicenses`, null, { root: true });
  // If we have the licenses API endpoint, fetch from there. This corresponds
  // to the cases that we're viewing the merge request or pipeline pages.
  // Otherwise, fetch from the managed licenses endpoint, which corresponds to
  // the project settings page.
  // https://gitlab.com/gitlab-org/gitlab/issues/201867
  if (state.licensesApiPath) {
    return dispatch('fetchParsedLicenseReport');
  }
  return dispatch('fetchManagedLicenses').then(() => {
    dispatch('removePendingLicense', id);
  });
};
export const receiveSetLicenseApprovalError = ({ commit }) => {
  commit(types.RESET_LICENSE_IN_MODAL);
};

export const fetchLicenseCheckApprovalRule = ({ dispatch, state }) => {
  dispatch('requestLicenseCheckApprovalRule');

  /* 
    If we call this action from the "License" tab in the pipeline view,
    then we don't fetch the approvals since we aren't in the Merge request context.
    Pipelines cannot have approval rules.
  */
  if (!state.approvalsApiPath) {
    return dispatch(
      'receiveLicenseCheckApprovalRuleError',
      new Error('approvalsApiPath not provided'),
    );
  }

  return axios
    .get(state.approvalsApiPath)
    .then(({ data }) => {
      const hasLicenseCheckApprovalRule = data.approval_rules_left.some((rule) => {
        return rule.name === LICENSE_CHECK_NAME;
      });

      dispatch('receiveLicenseCheckApprovalRuleSuccess', { hasLicenseCheckApprovalRule });
    })
    .catch((error) => {
      dispatch('receiveLicenseCheckApprovalRuleError', error);
    });
};

export const requestLicenseCheckApprovalRule = ({ commit }) => {
  commit(types.REQUEST_LICENSE_CHECK_APPROVAL_RULE);
};

export const receiveLicenseCheckApprovalRuleSuccess = ({ commit }, rule) => {
  commit(types.RECEIVE_LICENSE_CHECK_APPROVAL_RULE_SUCCESS, rule);
};

export const receiveLicenseCheckApprovalRuleError = ({ commit }, error) => {
  commit(types.RECEIVE_LICENSE_CHECK_APPROVAL_RULE_ERROR, error);
};

export const addPendingLicense = ({ state, commit }, id = null) => {
  if (!state.pendingLicenses.includes(id)) {
    commit(types.ADD_PENDING_LICENSE, id);
  }
};

export const removePendingLicense = ({ commit }, id = null) => {
  commit(types.REMOVE_PENDING_LICENSE, id);
};

export const setLicenseApproval = ({ dispatch, state }, payload) => {
  const { apiUrlManageLicenses } = state;
  const { license, newStatus } = payload;
  const { id, name } = license;

  dispatch('addPendingLicense', id);

  let request;

  /*
   Licenses that have an ID, are already in the database.
   So we need to send PATCH instead of POST.
   */
  if (id) {
    request = axios.patch(`${apiUrlManageLicenses}/${id}`, { approval_status: newStatus });
  } else {
    request = axios.post(apiUrlManageLicenses, { approval_status: newStatus, name });
  }

  return request
    .then(() => {
      dispatch('receiveSetLicenseApproval', id);
    })
    .catch(() => {
      dispatch('receiveSetLicenseApprovalError');
      dispatch('removePendingLicense', id);
    });
};
export const allowLicense = ({ dispatch }, license) => {
  const { approvalStatus } = license;
  if (approvalStatus !== LICENSE_APPROVAL_STATUS.ALLOWED) {
    dispatch('setLicenseApproval', { license, newStatus: LICENSE_APPROVAL_STATUS.ALLOWED });
  }
};

export const denyLicense = ({ dispatch }, license) => {
  const { approvalStatus } = license;
  if (approvalStatus !== LICENSE_APPROVAL_STATUS.DENIED) {
    dispatch('setLicenseApproval', { license, newStatus: LICENSE_APPROVAL_STATUS.DENIED });
  }
};
