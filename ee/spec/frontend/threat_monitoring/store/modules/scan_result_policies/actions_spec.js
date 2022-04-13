import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/threat_monitoring/store/modules/scan_result_policies/actions';
import * as types from 'ee/threat_monitoring/store/modules/scan_result_policies/mutation_types';
import getInitialState from 'ee/threat_monitoring/store/modules/scan_result_policies/state';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

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
      status                  | mutations
      ${httpStatus.OK}        | ${[]}
      ${httpStatus.NOT_FOUND} | ${[{ type: types.INVALID_BRANCHES, payload: branchName }]}
    `('triggers $mutations.length mutation when status is $status', ({ status, mutations }) => {
      mock.onGet(apiEndpoint).replyOnce(status);
      testAction(actions.fetchBranch, { branch: branchName, projectId }, state, mutations, []);
    });
  });
});
