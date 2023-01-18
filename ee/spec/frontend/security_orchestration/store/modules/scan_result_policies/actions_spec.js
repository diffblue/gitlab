import MockAdapter from 'axios-mock-adapter';
import * as types from 'ee/security_orchestration/store/modules/scan_result_policies/mutation_types';
import getInitialState from 'ee/security_orchestration/store/modules/scan_result_policies/state';
import * as actions from 'ee/security_orchestration/store/modules/scan_result_policies/actions';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('ScanResultPolicies actions', () => {
  let state;
  let mock;
  const projectId = 3;
  const branchName = 'main';
  const branches = [branchName];
  const duplicatedBranches = [branchName, branchName];
  const apiEndpoint = `/api/undefined/projects/${projectId}/protected_branches/${branchName}`;

  beforeEach(() => {
    state = getInitialState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchBranches', () => {
    it('commits LOADING_BRANCHES and dispatch calls to fetchBranch', () =>
      testAction(
        actions.fetchBranches,
        { branches, projectId },
        state,
        [
          {
            type: types.LOADING_BRANCHES,
          },
        ],
        [
          {
            type: 'fetchBranch',
            payload: {
              branch: branchName,
              projectId,
            },
          },
        ],
      ));

    it('only considers unique branches', () =>
      testAction(
        actions.fetchBranches,
        { branches: duplicatedBranches, projectId },
        state,
        [
          {
            type: types.LOADING_BRANCHES,
          },
        ],
        [
          {
            type: 'fetchBranch',
            payload: {
              branch: branchName,
              projectId,
            },
          },
        ],
      ));
  });

  describe('fetchBranch', () => {
    it.each`
      status                   | mutations
      ${HTTP_STATUS_OK}        | ${[]}
      ${HTTP_STATUS_NOT_FOUND} | ${[{ type: types.INVALID_PROTECTED_BRANCHES, payload: branchName }]}
    `('triggers $mutations.length mutation when status is $status', ({ status, mutations }) => {
      mock.onGet(apiEndpoint).replyOnce(status);
      testAction(actions.fetchBranch, { branch: branchName, projectId }, state, mutations, []);
    });
  });
});
