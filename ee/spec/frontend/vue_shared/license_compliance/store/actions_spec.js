import MockAdapter from 'axios-mock-adapter';
import { LICENSE_CHECK_NAME } from 'ee/approvals/constants';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';
import * as actions from 'ee/vue_shared/license_compliance/store/actions';
import * as mutationTypes from 'ee/vue_shared/license_compliance/store/mutation_types';
import createState from 'ee/vue_shared/license_compliance/store/state';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import { allowedLicense, deniedLicense } from '../mock_data';

describe('License store actions', () => {
  const apiUrlManageLicenses = `${TEST_HOST}/licenses/management`;
  const approvalsApiPath = `${TEST_HOST}/approvalsApiPath`;
  const licensesApiPath = `${TEST_HOST}/licensesApiPath`;

  let axiosMock;
  let licenseId;
  let state;
  let mockDispatch;
  let mockCommit;
  let store;

  const expectDispatched = (...args) => expect(mockDispatch).toHaveBeenCalledWith(...args);

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    state = {
      ...createState(),
      apiUrlManageLicenses,
      approvalsApiPath,
      currentLicenseInModal: allowedLicense,
    };
    licenseId = allowedLicense.id;
    mockDispatch = jest.fn(() => Promise.resolve());
    mockCommit = jest.fn();
    store = {
      state,
      commit: mockCommit,
      dispatch: mockDispatch,
    };
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('setAPISettings', () => {
    it('commits SET_API_SETTINGS', async () => {
      const payload = { apiUrlManageLicenses };
      await testAction(
        actions.setAPISettings,
        payload,
        state,
        [{ type: mutationTypes.SET_API_SETTINGS, payload }],
        [],
      );
    });
  });

  describe('setKnownLicenses', () => {
    it('commits SET_KNOWN_LICENSES', async () => {
      const payload = [{ name: 'BSD' }, { name: 'Apache' }];
      await testAction(
        actions.setKnownLicenses,
        payload,
        state,
        [{ type: mutationTypes.SET_KNOWN_LICENSES, payload }],
        [],
      );
    });
  });

  describe('setLicenseInModal', () => {
    it('commits SET_LICENSE_IN_MODAL with license', async () => {
      await testAction(
        actions.setLicenseInModal,
        allowedLicense,
        state,
        [{ type: mutationTypes.SET_LICENSE_IN_MODAL, payload: allowedLicense }],
        [],
      );
    });
  });

  describe('setIsAdmin', () => {
    it('commits SET_IS_ADMIN', async () => {
      await testAction(
        actions.setIsAdmin,
        false,
        state,
        [{ type: mutationTypes.SET_IS_ADMIN, payload: false }],
        [],
      );
    });
  });

  describe('resetLicenseInModal', () => {
    it('commits RESET_LICENSE_IN_MODAL', async () => {
      await testAction(
        actions.resetLicenseInModal,
        null,
        state,
        [{ type: mutationTypes.RESET_LICENSE_IN_MODAL }],
        [],
      );
    });
  });

  describe('receiveDeleteLicense', () => {
    it('commits RESET_LICENSE_IN_MODAL and dispatches licenseList/fetchLicenses, fetchManagedLicenses and removePendingLicense', () => {
      return actions.receiveDeleteLicense(store, licenseId).then(() => {
        expect(mockCommit).toHaveBeenCalledWith(mutationTypes.RESET_LICENSE_IN_MODAL);
        expectDispatched('licenseList/fetchLicenses', null, { root: true });
        expectDispatched('fetchManagedLicenses');
        expectDispatched('removePendingLicense', licenseId);
      });
    });
  });

  describe('receiveDeleteLicenseError', () => {
    it('commits RESET_LICENSE_IN_MODAL', async () => {
      await testAction(
        actions.receiveDeleteLicenseError,
        null,
        state,
        [{ type: mutationTypes.RESET_LICENSE_IN_MODAL }],
        [],
      );
    });
  });

  describe('deleteLicense', () => {
    let endpointMock;
    let deleteUrl;

    beforeEach(() => {
      deleteUrl = `${apiUrlManageLicenses}/${licenseId}`;
      endpointMock = axiosMock.onDelete(deleteUrl);
    });

    it('dispatches addPendingLicense and receiveDeleteLicense for successful response', () => {
      endpointMock.replyOnce((req) => {
        expect(req.url).toBe(deleteUrl);
        return [HTTP_STATUS_OK, ''];
      });

      return actions.deleteLicense(store).then(() => {
        expectDispatched('addPendingLicense', licenseId);
        expectDispatched('receiveDeleteLicense', licenseId);
      });
    });

    it('dispatches addPendingLicense, receiveDeleteLicenseError and removePendingLicense for error response', () => {
      endpointMock.replyOnce((req) => {
        expect(req.url).toBe(deleteUrl);
        return [HTTP_STATUS_INTERNAL_SERVER_ERROR, ''];
      });

      return actions.deleteLicense(store).then(() => {
        expectDispatched('addPendingLicense', licenseId);
        expectDispatched('receiveDeleteLicenseError');
        expectDispatched('removePendingLicense', licenseId);
      });
    });
  });

  describe('receiveSetLicenseApproval', () => {
    describe('given the licensesApiPath is provided', () => {
      it('commits RESET_LICENSE_IN_MODAL and dispatches licenseList/fetchLicenses and fetchParsedLicenseReport', async () => {
        await testAction(
          actions.receiveSetLicenseApproval,
          null,
          { ...state, licensesApiPath },
          [{ type: mutationTypes.RESET_LICENSE_IN_MODAL }],
          [
            { type: `licenseList/fetchLicenses`, payload: null },
            { type: 'fetchParsedLicenseReport' },
          ],
        );
      });
    });

    describe('given the licensesApiPath is not provided', () => {
      it('commits RESET_LICENSE_IN_MODAL and dispatches licenseList/fetchLicenses, fetchManagedLicenses and removePendingLicense', () => {
        return actions.receiveSetLicenseApproval(store, licenseId).then(() => {
          expect(mockCommit).toHaveBeenCalledWith(mutationTypes.RESET_LICENSE_IN_MODAL);
          expectDispatched('licenseList/fetchLicenses', null, { root: true });
          expectDispatched('fetchManagedLicenses');
          expectDispatched('removePendingLicense', licenseId);
        });
      });
    });
  });

  describe('receiveSetLicenseApprovalError', () => {
    it('commits RESET_LICENSE_IN_MODAL', async () => {
      await testAction(
        actions.receiveSetLicenseApprovalError,
        null,
        state,
        [{ type: mutationTypes.RESET_LICENSE_IN_MODAL }],
        [],
      );
    });
  });

  describe('setLicenseApproval', () => {
    const newStatus = 'FAKE_STATUS';

    describe('uses POST endpoint for existing licenses;', () => {
      let putEndpointMock;
      let newLicense;

      beforeEach(() => {
        newLicense = { name: 'FOO LICENSE' };
        putEndpointMock = axiosMock.onPost(apiUrlManageLicenses);
      });

      it('dispatches addPendingLicense and receiveSetLicenseApproval for successful response', () => {
        putEndpointMock.replyOnce((req) => {
          const { approval_status, name } = JSON.parse(req.data);

          expect(req.url).toBe(apiUrlManageLicenses);
          expect(approval_status).toBe(newStatus);
          expect(name).toBe(name);
          return [HTTP_STATUS_OK, ''];
        });

        return actions.setLicenseApproval(store, { license: newLicense, newStatus }).then(() => {
          expectDispatched('addPendingLicense', undefined);
          expectDispatched('receiveSetLicenseApproval', undefined);
        });
      });

      it('dispatches addPendingLicense, receiveSetLicenseApprovalError and removePendingLicense for error response', () => {
        putEndpointMock.replyOnce((req) => {
          expect(req.url).toBe(apiUrlManageLicenses);
          return [HTTP_STATUS_INTERNAL_SERVER_ERROR, ''];
        });

        return actions.setLicenseApproval(store, { license: newLicense, newStatus }).then(() => {
          expectDispatched('addPendingLicense', undefined);
          expectDispatched('receiveSetLicenseApprovalError');
          expectDispatched('removePendingLicense', undefined);
        });
      });
    });

    describe('uses PATCH endpoint for existing licenses;', () => {
      let patchEndpointMock;
      let licenseUrl;

      beforeEach(() => {
        licenseUrl = `${apiUrlManageLicenses}/${licenseId}`;
        patchEndpointMock = axiosMock.onPatch(licenseUrl);
      });

      it('dispatches addPendingLicense and receiveSetLicenseApproval for successful response', () => {
        patchEndpointMock.replyOnce((req) => {
          expect(req.url).toBe(licenseUrl);
          const { approval_status, name } = JSON.parse(req.data);

          expect(approval_status).toBe(newStatus);
          expect(name).toBeUndefined();
          return [HTTP_STATUS_OK, ''];
        });

        return actions
          .setLicenseApproval(store, { license: allowedLicense, newStatus })
          .then(() => {
            expectDispatched('addPendingLicense', allowedLicense.id);
            expectDispatched('receiveSetLicenseApproval', allowedLicense.id);
          });
      });

      it('dispatches addPendingLicense, receiveSetLicenseApprovalError and removePendingLicense for error response', () => {
        patchEndpointMock.replyOnce((req) => {
          expect(req.url).toBe(licenseUrl);
          return [HTTP_STATUS_INTERNAL_SERVER_ERROR, ''];
        });

        return actions
          .setLicenseApproval(store, { license: allowedLicense, newStatus })
          .then(() => {
            expectDispatched('addPendingLicense', allowedLicense.id);
            expectDispatched('receiveSetLicenseApprovalError');
            expectDispatched('removePendingLicense', allowedLicense.id);
          });
      });
    });
  });

  describe('allowLicense', () => {
    const newStatus = LICENSE_APPROVAL_STATUS.ALLOWED;

    it('dispatches setLicenseApproval for un-allowed licenses', async () => {
      const license = { name: 'FOO' };

      await testAction(
        actions.allowLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      );
    });

    it('dispatches setLicenseApproval for denied licenses', async () => {
      const license = deniedLicense;

      await testAction(
        actions.allowLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      );
    });

    it('does not dispatch setLicenseApproval for allowed licenses', async () => {
      await testAction(actions.allowLicense, allowedLicense, state, [], []);
    });
  });

  describe('denyLicense', () => {
    const newStatus = LICENSE_APPROVAL_STATUS.DENIED;

    it('dispatches setLicenseApproval for un-allowed licenses', async () => {
      const license = { name: 'FOO' };

      await testAction(
        actions.denyLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      );
    });

    it('dispatches setLicenseApproval for allowed licenses', async () => {
      const license = allowedLicense;

      await testAction(
        actions.denyLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      );
    });

    it('does not dispatch setLicenseApproval for denied licenses', async () => {
      await testAction(actions.denyLicense, deniedLicense, state, [], []);
    });
  });

  describe('requestManagedLicenses', () => {
    it('commits REQUEST_MANAGED_LICENSES', async () => {
      await testAction(
        actions.requestManagedLicenses,
        null,
        state,
        [{ type: mutationTypes.REQUEST_MANAGED_LICENSES }],
        [],
      );
    });
  });

  describe('receiveManagedLicensesSuccess', () => {
    it('commits RECEIVE_MANAGED_LICENSES_SUCCESS', async () => {
      const payload = [allowedLicense];
      await testAction(
        actions.receiveManagedLicensesSuccess,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_MANAGED_LICENSES_SUCCESS, payload }],
        [],
      );
    });
  });

  describe('receiveManagedLicensesError', () => {
    it('commits RECEIVE_MANAGED_LICENSES_ERROR', async () => {
      const error = new Error('Test');
      await testAction(
        actions.receiveManagedLicensesError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_MANAGED_LICENSES_ERROR }],
        [],
      );
    });
  });

  describe('fetchManagedLicenses', () => {
    let endpointMock;

    beforeEach(() => {
      endpointMock = axiosMock.onGet(apiUrlManageLicenses, { params: { per_page: 100 } });
    });

    it('dispatches requestManagedLicenses and receiveManagedLicensesSuccess for successful response', async () => {
      const payload = [{ name: 'foo', approval_status: LICENSE_APPROVAL_STATUS.DENIED }];
      endpointMock.replyOnce(() => [HTTP_STATUS_OK, payload]);

      await testAction(
        actions.fetchManagedLicenses,
        null,
        state,
        [],
        [{ type: 'requestManagedLicenses' }, { type: 'receiveManagedLicensesSuccess', payload }],
      );
    });

    it('dispatches requestManagedLicenses and receiveManagedLicensesError for error response', async () => {
      endpointMock.replyOnce(() => [HTTP_STATUS_INTERNAL_SERVER_ERROR, '']);

      await testAction(
        actions.fetchManagedLicenses,
        null,
        state,
        [],
        [{ type: 'requestManagedLicenses' }, { type: 'receiveManagedLicensesError' }],
      );
    });
  });

  describe('fetchLicenseCheckApprovalRule', () => {
    it('dispatches request/receive with detected approval rule', async () => {
      const APPROVAL_RULE_RESPONSE = {
        approval_rules_left: [{ name: LICENSE_CHECK_NAME }],
      };

      axiosMock.onGet(approvalsApiPath).replyOnce(HTTP_STATUS_OK, APPROVAL_RULE_RESPONSE);

      await testAction(
        actions.fetchLicenseCheckApprovalRule,
        null,
        state,
        [],
        [
          { type: 'requestLicenseCheckApprovalRule' },
          {
            type: 'receiveLicenseCheckApprovalRuleSuccess',
            payload: { hasLicenseCheckApprovalRule: true },
          },
        ],
      );
    });

    it('dispatches request/receive without detected approval rule', async () => {
      const APPROVAL_RULE_RESPONSE = {
        approval_rules_left: [{ name: 'Another Approval Rule' }],
      };

      axiosMock.onGet(approvalsApiPath).replyOnce(HTTP_STATUS_OK, APPROVAL_RULE_RESPONSE);

      await testAction(
        actions.fetchLicenseCheckApprovalRule,
        null,
        state,
        [],
        [
          { type: 'requestLicenseCheckApprovalRule' },
          {
            type: 'receiveLicenseCheckApprovalRuleSuccess',
            payload: { hasLicenseCheckApprovalRule: false },
          },
        ],
      );
    });

    it('dispatches request/receive error when no approvalsAPiPath is provided', async () => {
      const error = new Error('approvalsApiPath not provided');
      axiosMock.onGet(approvalsApiPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(
        actions.fetchLicenseCheckApprovalRule,
        null,
        { ...state, approvalsApiPath: '' },
        [],
        [
          { type: 'requestLicenseCheckApprovalRule' },
          { type: 'receiveLicenseCheckApprovalRuleError', payload: error },
        ],
      );
    });

    it('dispatches request/receive on error', async () => {
      const error = new Error('Request failed with status code 500');
      axiosMock.onGet(approvalsApiPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(
        actions.fetchLicenseCheckApprovalRule,
        null,
        state,
        [],
        [
          { type: 'requestLicenseCheckApprovalRule' },
          { type: 'receiveLicenseCheckApprovalRuleError', payload: error },
        ],
      );
    });
  });

  describe('requestLicenseCheckApprovalRule', () => {
    it('commits REQUEST_LICENSE_CHECK_APPROVAL_RULE', async () => {
      await testAction(
        actions.requestLicenseCheckApprovalRule,
        null,
        state,
        [{ type: mutationTypes.REQUEST_LICENSE_CHECK_APPROVAL_RULE }],
        [],
      );
    });
  });

  describe('receiveLicenseCheckApprovalRuleSuccess', () => {
    it('commits REQUEST_LICENSE_CHECK_APPROVAL_RULE', async () => {
      const hasLicenseCheckApprovalRule = true;

      await testAction(
        actions.receiveLicenseCheckApprovalRuleSuccess,
        { hasLicenseCheckApprovalRule },
        state,
        [
          {
            type: mutationTypes.RECEIVE_LICENSE_CHECK_APPROVAL_RULE_SUCCESS,
            payload: { hasLicenseCheckApprovalRule },
          },
        ],
        [],
      );
    });
  });

  describe('receiveLicenseCheckApprovalRuleError', () => {
    it('commits RECEIVE_LICENSE_CHECK_APPROVAL_RULE_ERROR', async () => {
      const error = new Error('Error');

      await testAction(
        actions.receiveLicenseCheckApprovalRuleError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_LICENSE_CHECK_APPROVAL_RULE_ERROR, payload: error }],
        [],
      );
    });
  });

  describe('requestParsedLicenseReport', () => {
    it(`should commit ${mutationTypes.REQUEST_PARSED_LICENSE_REPORT}`, async () => {
      await testAction(
        actions.requestParsedLicenseReport,
        null,
        state,
        [{ type: mutationTypes.REQUEST_PARSED_LICENSE_REPORT }],
        [],
      );
    });
  });

  describe('receiveParsedLicenseReportSuccess', () => {
    it(`should commit ${mutationTypes.RECEIVE_PARSED_LICENSE_REPORT_SUCCESS} with the correct payload`, async () => {
      const payload = { newLicenses: [{ name: 'foo' }] };

      await testAction(
        actions.receiveParsedLicenseReportSuccess,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_PARSED_LICENSE_REPORT_SUCCESS, payload }],
        [],
      );
    });
  });

  describe('receiveParsedLicenseReportError', () => {
    it(`should commit ${mutationTypes.RECEIVE_PARSED_LICENSE_REPORT_ERROR}`, async () => {
      const payload = new Error('Test');

      await testAction(
        actions.receiveParsedLicenseReportError,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_PARSED_LICENSE_REPORT_ERROR, payload }],
        [],
      );
    });
  });

  describe('fetchParsedLicenseReport', () => {
    let licensesApiMock;
    let rawLicenseReport;

    beforeEach(() => {
      licensesApiMock = axiosMock.onGet(licensesApiPath);
      state = {
        ...createState(),
        licensesApiPath,
      };
    });

    describe('pipeline reports', () => {
      beforeEach(() => {
        rawLicenseReport = [
          {
            name: 'MIT',
            classification: { id: 2, approval_status: LICENSE_APPROVAL_STATUS.DENIED, name: 'MIT' },
            dependencies: [{ name: 'vue' }],
            count: 1,
            url: 'http://opensource.org/licenses/mit-license',
          },
        ];
      });

      it('should fetch, parse, and dispatch the new licenses on a successful request', async () => {
        licensesApiMock.replyOnce(() => [HTTP_STATUS_OK, rawLicenseReport]);

        const parsedLicenses = {
          existingLicenses: [],
          newLicenses: [
            {
              ...rawLicenseReport[0],
              id: 2,
              approvalStatus: LICENSE_APPROVAL_STATUS.DENIED,
              packages: [{ name: 'vue' }],
              status: 'failed',
            },
          ],
        };

        await testAction(
          actions.fetchParsedLicenseReport,
          null,
          state,
          [],
          [
            { type: 'requestParsedLicenseReport' },
            { type: 'receiveParsedLicenseReportSuccess', payload: parsedLicenses },
          ],
        );
      });

      it('should send an error on an unsuccesful request', async () => {
        licensesApiMock.replyOnce(HTTP_STATUS_BAD_REQUEST);

        await testAction(
          actions.fetchParsedLicenseReport,
          null,
          state,
          [],
          [
            { type: 'requestParsedLicenseReport' },
            { type: 'receiveParsedLicenseReportError', payload: expect.any(Error) },
          ],
        );
      });
    });

    describe('MR widget reports', () => {
      beforeEach(() => {
        rawLicenseReport = {
          new_licenses: [
            {
              name: 'Apache 2.0',
              classification: {
                id: 1,
                approval_status: LICENSE_APPROVAL_STATUS.ALLOWED,
                name: 'Apache 2.0',
              },
              dependencies: [{ name: 'echarts' }],
              count: 1,
              url: 'http://www.apache.org/licenses/LICENSE-2.0.txt',
            },
            {
              name: 'New BSD',
              classification: { id: 3, approval_status: 'unclassified', name: 'New BSD' },
              dependencies: [{ name: 'zrender' }],
              count: 1,
              url: 'http://opensource.org/licenses/BSD-3-Clause',
            },
          ],
          existing_licenses: [
            {
              name: 'MIT',
              classification: {
                id: 2,
                approval_status: LICENSE_APPROVAL_STATUS.DENIED,
                name: 'MIT',
              },
              dependencies: [{ name: 'vue' }],
              count: 1,
              url: 'http://opensource.org/licenses/mit-license',
            },
          ],
          removed_licenses: [],
        };
      });

      it('should fetch, parse, and dispatch the new licenses on a successful request', async () => {
        licensesApiMock.replyOnce(() => [HTTP_STATUS_OK, rawLicenseReport]);

        const parsedLicenses = {
          existingLicenses: [
            {
              ...rawLicenseReport.existing_licenses[0],
              id: 2,
              approvalStatus: LICENSE_APPROVAL_STATUS.DENIED,
              packages: [{ name: 'vue' }],
              status: 'failed',
            },
          ],
          newLicenses: [
            {
              ...rawLicenseReport.new_licenses[0],
              id: 1,
              approvalStatus: LICENSE_APPROVAL_STATUS.ALLOWED,
              packages: [{ name: 'echarts' }],
              status: 'success',
            },
            {
              ...rawLicenseReport.new_licenses[1],
              id: 3,
              approvalStatus: 'unclassified',
              packages: [{ name: 'zrender' }],
              status: 'neutral',
            },
          ],
        };

        await testAction(
          actions.fetchParsedLicenseReport,
          null,
          state,
          [],
          [
            { type: 'requestParsedLicenseReport' },
            { type: 'receiveParsedLicenseReportSuccess', payload: parsedLicenses },
          ],
        );
      });
    });
  });
});
