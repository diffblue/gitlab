import * as types from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/vulnerabilities/mutations';
import createState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import { HTTP_STATUS_FORBIDDEN } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import mockData from './data/mock_data_vulnerabilities';

jest.mock('~/lib/utils/url_utility');

const DISMISSAL_STATE_TRANSITION = { toState: 'DISMISSED' };
const GRAPHQL_DISMISS_MUTATION_RESPONSE = {
  securityFindingDismiss: {
    securityFinding: {
      vulnerability: {
        stateTransitions: { nodes: [DISMISSAL_STATE_TRANSITION] },
      },
    },
  },
};
const EXPECTED_DISMISSAL_TRANSITIONS = [convertObjectPropsToSnakeCase(DISMISSAL_STATE_TRANSITION)];
const EXPECTED_DISMISSAL_STATE = DISMISSAL_STATE_TRANSITION.toState.toLowerCase();

describe('vulnerabilities module mutations', () => {
  let state;

  beforeEach(() => {
    gon.features = { deprecateVulnerabilitiesFeedback: true };
    state = createState();
  });

  describe('SET_PIPELINE_ID', () => {
    const pipelineId = 123;

    it(`should set the pipelineId to ${pipelineId}`, () => {
      mutations[types.SET_PIPELINE_ID](state, pipelineId);

      expect(state.pipelineId).toBe(pipelineId);
    });
  });

  describe('SET_SOURCE_BRANCH', () => {
    const sourceBranch = 'feature-branch-1';

    it(`should set the sourceBranch to ${sourceBranch}`, () => {
      mutations[types.SET_SOURCE_BRANCH](state, sourceBranch);

      expect(state.sourceBranch).toBe(sourceBranch);
    });
  });

  describe('SET_VULNERABILITIES_ENDPOINT', () => {
    it('should set `vulnerabilitiesEndpoint` to `fakepath.json`', () => {
      const endpoint = 'fakepath.json';

      mutations[types.SET_VULNERABILITIES_ENDPOINT](state, endpoint);

      expect(state.vulnerabilitiesEndpoint).toBe(endpoint);
    });
  });

  describe('SET_VULNERABILITIES_PAGE', () => {
    const page = 3;
    it(`should set pageInfo.page to ${page}`, () => {
      mutations[types.SET_VULNERABILITIES_PAGE](state, page);

      expect(state.pageInfo.page).toBe(page);
    });
  });

  describe('REQUEST_VULNERABILITIES', () => {
    it('should set properties to expected values', () => {
      state.errorLoadingVulnerabilities = true;
      state.loadingVulnerabilitiesErrorCode = HTTP_STATUS_FORBIDDEN;
      mutations[types.REQUEST_VULNERABILITIES](state);

      expect(state).toMatchObject({
        isLoadingVulnerabilities: true,
        errorLoadingVulnerabilities: false,
        loadingVulnerabilitiesErrorCode: null,
      });
    });
  });

  describe('RECEIVE_VULNERABILITIES_SUCCESS', () => {
    let payload;

    beforeEach(() => {
      payload = {
        vulnerabilities: mockData,
        pageInfo: { a: 1, b: 2, c: 3 },
      };
      mutations[types.RECEIVE_VULNERABILITIES_SUCCESS](state, payload);
    });

    it('should set `isLoadingVulnerabilities` to `false`', () => {
      expect(state.isLoadingVulnerabilities).toBe(false);
    });

    it('should set `pageInfo`', () => {
      expect(state.pageInfo).toBe(payload.pageInfo);
    });

    it('should set `vulnerabilities`', () => {
      expect(state.vulnerabilities).toBe(payload.vulnerabilities);
    });
  });

  describe('RECEIVE_VULNERABILITIES_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_VULNERABILITIES_ERROR](state, HTTP_STATUS_FORBIDDEN);
    });

    it('should set `isLoadingVulnerabilities` to `false`', () => {
      expect(state.isLoadingVulnerabilities).toBe(false);
    });

    it('should set `loadingVulnerabilitiesErrorCode`', () => {
      expect(state.loadingVulnerabilitiesErrorCode).toBe(HTTP_STATUS_FORBIDDEN);
    });
  });

  describe('SET_MODAL_DATA', () => {
    describe('with all the data', () => {
      const vulnerability = mockData[0];
      let payload;

      beforeEach(() => {
        payload = { vulnerability };
        mutations[types.SET_MODAL_DATA](state, payload);
      });

      it('should set the modal title', () => {
        expect(state.modal.title).toBe(vulnerability.name);
      });

      it('should set the modal project', () => {
        expect(state.modal.project.value).toBe(vulnerability.project.full_name);
        expect(state.modal.project.url).toBe(vulnerability.project.full_path);
      });

      it('should set the modal vulnerability', () => {
        expect(state.modal.vulnerability).toEqual(vulnerability);
      });
    });

    describe('with irregular data', () => {
      const vulnerability = mockData[0];
      it('should set isDismissed when the vulnerability is dismissed', () => {
        const payload = {
          vulnerability: { ...vulnerability, dismissal_feedback: 'I am dismissed' },
        };
        mutations[types.SET_MODAL_DATA](state, payload);

        expect(state.modal.vulnerability.isDismissed).toBe(true);
      });
    });
  });

  describe('REQUEST_CREATE_ISSUE', () => {
    beforeEach(() => {
      mutations[types.REQUEST_CREATE_ISSUE](state);
    });

    it('should set isCreatingIssue to true', () => {
      expect(state.isCreatingIssue).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(state.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_CREATE_ISSUE_SUCCESS', () => {
    it('should visit the issue URL', () => {
      const path = 'fakepath.html';
      const payload = { issue_links: [{ link_type: 'created', issue_url: path }] };
      mutations[types.RECEIVE_CREATE_ISSUE_SUCCESS](state, payload);

      expect(visitUrl).toHaveBeenCalledWith(path);
    });

    it('should visit the issue URL - deprecateVulnerabilitiesFeedback feature flag disabled', () => {
      gon.features = { deprecateVulnerabilitiesFeedback: false };
      const payload = { issue_url: 'fakepath.html' };
      mutations[types.RECEIVE_CREATE_ISSUE_SUCCESS](state, payload);

      expect(visitUrl).toHaveBeenCalledWith(payload.issue_url);
    });
  });

  describe('RECEIVE_CREATE_ISSUE_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_CREATE_ISSUE_ERROR](state);
    });

    it('should set isCreatingIssue to false', () => {
      expect(state.isCreatingIssue).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(state.modal.error).toBe('There was an error creating the issue');
    });
  });

  describe('REQUEST_CREATE_MERGE_REQUEST', () => {
    beforeEach(() => {
      mutations[types.REQUEST_CREATE_MERGE_REQUEST](state);
    });

    it('should set isCreatingMergeRequest to true', () => {
      expect(state.isCreatingMergeRequest).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(state.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_CREATE_MERGE_REQUEST_SUCCESS', () => {
    it('should visit the merge request URL', () => {
      const path = 'fakepath.html';
      const payload = { merge_request_links: [{ merge_request_path: path }] };
      mutations[types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS](state, payload);

      expect(visitUrl).toHaveBeenCalledWith(path);
    });

    it('should visit the merge request URL - deprecateVulnerabilitiesFeedback feature flag disabled', () => {
      gon.features = { deprecateVulnerabilitiesFeedback: false };
      const path = 'fakepath.html';
      const payload = { merge_request_path: path };
      mutations[types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS](state, payload);

      expect(visitUrl).toHaveBeenCalledWith(path);
    });
  });

  describe('RECEIVE_CREATE_MERGE_REQUEST_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_CREATE_MERGE_REQUEST_ERROR](state);
    });

    it('should set isCreatingMergeRequest to false', () => {
      expect(state.isCreatingMergeRequest).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(state.modal.error).toBe('There was an error creating the merge request');
    });
  });

  describe('REQUEST_DISMISS_VULNERABILITY', () => {
    beforeEach(() => {
      mutations[types.REQUEST_DISMISS_VULNERABILITY](state);
    });

    it('should set isDismissingVulnerability to true', () => {
      expect(state.isDismissingVulnerability).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(state.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_DISMISS_VULNERABILITY_SUCCESS', () => {
    let vulnerability;
    let data;

    beforeEach(() => {
      state.vulnerabilities = mockData;
      [vulnerability] = mockData;
    });

    describe('deprecateVulnerabilitiesFeedback feature flag enabled', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS](state, {
          vulnerability,
          data: GRAPHQL_DISMISS_MUTATION_RESPONSE,
        });
      });

      it('should set the dismissal feedback on the passed vulnerability', () => {
        expect(vulnerability.state).toBe(EXPECTED_DISMISSAL_STATE);
        expect(vulnerability.state_transitions).toEqual(EXPECTED_DISMISSAL_TRANSITIONS);
      });

      it('should set isDismissingVulnerability to false', () => {
        expect(state.isDismissingVulnerability).toBe(false);
      });

      it('should set isDismissed on the modal vulnerability to be true', () => {
        expect(state.modal.vulnerability.isDismissed).toBe(true);
      });
    });

    describe('deprecateVulnerabilitiesFeedback feature flag disabled', () => {
      beforeEach(() => {
        data = { name: 'dismissal feedback' };
        gon.features = { deprecateVulnerabilitiesFeedback: false };
        mutations[types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS](state, { vulnerability, data });
      });

      it('should set the dismissal feedback on the passed vulnerability', () => {
        expect(vulnerability.dismissal_feedback).toEqual(data);
      });

      it('should set isDismissingVulnerability to false', () => {
        expect(state.isDismissingVulnerability).toBe(false);
      });

      it('should set isDismissed on the modal vulnerability to be true', () => {
        expect(state.modal.vulnerability.isDismissed).toBe(true);
      });
    });
  });

  describe('RECEIVE_DISMISS_VULNERABILITY_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_DISMISS_VULNERABILITY_ERROR](state);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(state.isDismissingVulnerability).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(state.modal.error).toBe('There was an error dismissing the vulnerability.');
    });
  });

  describe('REQUEST_DISMISS_SELECTED_VULNERABILITIES', () => {
    beforeEach(() => {
      mutations[types.REQUEST_DISMISS_SELECTED_VULNERABILITIES](state);
    });

    it('should set isDismissingVulnerabilities to true', () => {
      expect(state.isDismissingVulnerabilities).toBe(true);
    });
  });

  describe('RECEIVE_DISMISS_SELECTED_VULNERABILITIES_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_SUCCESS](state);
    });

    it('should set isDismissingVulnerabilities to false', () => {
      expect(state.isDismissingVulnerabilities).toBe(false);
    });

    it('should remove all selected vulnerabilities', () => {
      expect(Object.keys(state.selectedVulnerabilities)).toHaveLength(0);
    });
  });

  describe('RECEIVE_DISMISS_SELECTED_VULNERABILITIES_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_ERROR](state);
    });

    it('should set isDismissingVulnerabilities to false', () => {
      expect(state.isDismissingVulnerabilities).toBe(false);
    });
  });

  describe('SELECT_VULNERABILITY', () => {
    const id = 1234;

    beforeEach(() => {
      mutations[types.SELECT_VULNERABILITY](state, id);
    });

    it('should add the vulnerability to selected vulnerabilities', () => {
      expect(state.selectedVulnerabilities[id]).toBe(true);
    });

    it('should not add a duplicate id to the selected vulnerabilities', () => {
      expect(state.selectedVulnerabilities).toStrictEqual({ [id]: true });
      mutations[types.SELECT_VULNERABILITY](state, id);

      expect(state.selectedVulnerabilities).toStrictEqual({ [id]: true });
    });
  });

  describe('DESELECT_VULNERABILITY', () => {
    beforeEach(() => {
      state.selectedVulnerabilities = { 12: true, 34: true, 56: true };
    });

    it('should remove the vulnerability from selected vulnerabilities', () => {
      const vulnerabilityId = 12;

      expect(state.selectedVulnerabilities[vulnerabilityId]).toBe(true);
      mutations[types.DESELECT_VULNERABILITY](state, vulnerabilityId);

      expect(state.selectedVulnerabilities[vulnerabilityId]).toBeUndefined();
    });
  });

  describe('SELECT_ALL_VULNERABILITIES', () => {
    beforeEach(() => {
      state.vulnerabilities = [{ id: 12 }, { id: 34 }, { id: 56 }];
      state.selectedVulnerabilities = {};
    });

    it('should add all the vulnerabilities when none are selected', () => {
      mutations[types.SELECT_ALL_VULNERABILITIES](state);

      expect(Object.keys(state.selectedVulnerabilities)).toHaveLength(state.vulnerabilities.length);
    });

    it('should add all the vulnerabilities when some are already selected', () => {
      state.selectedVulnerabilities = { 12: true, 13: true };
      mutations[types.SELECT_ALL_VULNERABILITIES](state);

      expect(Object.keys(state.selectedVulnerabilities)).toHaveLength(state.vulnerabilities.length);
    });
  });

  describe('DESELECT_ALL_VULNERABILITIES', () => {
    beforeEach(() => {
      state.selectedVulnerabilities = { 12: true, 34: true, 56: true };
      mutations[types.DESELECT_ALL_VULNERABILITIES](state);
    });

    it('should remove all selected vulnerabilities', () => {
      expect(Object.keys(state.selectedVulnerabilities)).toHaveLength(0);
    });
  });

  describe('REQUEST_DELETE_DISMISSAL_COMMENT', () => {
    beforeEach(() => {
      mutations[types.REQUEST_DELETE_DISMISSAL_COMMENT](state);
    });

    it('should set isDismissingVulnerability to true', () => {
      expect(state.isDismissingVulnerability).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(state.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS', () => {
    beforeEach(() => {
      state.vulnerabilities = mockData;
    });

    describe('deprecateVulnerabilitiesFeedback feature flag enabled', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS](state, {
          id: state.vulnerabilities[0].id,
          data: GRAPHQL_DISMISS_MUTATION_RESPONSE,
        });
      });

      it('should update the vulnerability state and state_transitions with payload data', () => {
        const vulnerability = state.vulnerabilities[0];

        expect(vulnerability.state).toBe(EXPECTED_DISMISSAL_STATE);
        expect(vulnerability.state_transitions).toEqual(EXPECTED_DISMISSAL_TRANSITIONS);
      });

      it('should set isDismissingVulnerability to false', () => {
        expect(state.isDismissingVulnerability).toBe(false);
      });

      it('should set isDismissed on the modal vulnerability to be true', () => {
        expect(state.modal.vulnerability.isDismissed).toBe(true);
      });
    });

    describe('deprecateVulnerabilitiesFeedback feature flag disabled', () => {
      const data = {};

      beforeEach(() => {
        gon.features.deprecateVulnerabilitiesFeedback = false;
        mutations[types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS](state, {
          id: state.vulnerabilities[0].id,
          data,
        });
      });

      it('should set the dismissal feedback to the payload data', () => {
        expect(state.vulnerabilities[0].dismissal_feedback).toEqual(data);
      });

      it('should set isDismissingVulnerability to false', () => {
        expect(state.isDismissingVulnerability).toBe(false);
      });

      it('should set isDismissed on the modal vulnerability to be true', () => {
        expect(state.modal.vulnerability.isDismissed).toBe(true);
      });
    });
  });

  describe('RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR](state);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(state.isDismissingVulnerability).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(state.modal.error).toBe('There was an error deleting the comment.');
    });
  });

  describe(types.SHOW_DISMISSAL_DELETE_BUTTONS, () => {
    beforeEach(() => {
      mutations[types.SHOW_DISMISSAL_DELETE_BUTTONS](state);
    });

    it('should set isShowingDeleteButtons to true', () => {
      expect(state.modal.isShowingDeleteButtons).toBe(true);
    });
  });

  describe(types.HIDE_DISMISSAL_DELETE_BUTTONS, () => {
    beforeEach(() => {
      mutations[types.HIDE_DISMISSAL_DELETE_BUTTONS](state);
    });

    it('should set isShowingDeleteButtons to false', () => {
      expect(state.modal.isShowingDeleteButtons).toBe(false);
    });
  });

  describe('REQUEST_ADD_DISMISSAL_COMMENT', () => {
    beforeEach(() => {
      mutations[types.REQUEST_ADD_DISMISSAL_COMMENT](state);
    });

    it('should set isDismissingVulnerability to true', () => {
      expect(state.isDismissingVulnerability).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(state.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS', () => {
    beforeEach(() => {
      state.vulnerabilities = mockData;
    });

    describe('deprecateVulnerabilitiesFeedback feature flag enabled', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS](state, {
          vulnerability: state.vulnerabilities[0],
          data: GRAPHQL_DISMISS_MUTATION_RESPONSE,
        });
      });

      it('should update the vulnerability state and state_transitions with payload data', () => {
        const vulnerability = state.vulnerabilities[0];

        expect(vulnerability.state).toBe(EXPECTED_DISMISSAL_STATE);
        expect(vulnerability.state_transitions).toEqual(EXPECTED_DISMISSAL_TRANSITIONS);
      });

      it('should set isDismissingVulnerability to false', () => {
        expect(state.isDismissingVulnerability).toBe(false);
      });

      it('should set isDismissed on the modal vulnerability to be true', () => {
        expect(state.modal.vulnerability.isDismissed).toBe(true);
      });
    });

    describe('deprecateVulnerabilitiesFeedback feature flag disabled', () => {
      const data = {};

      beforeEach(() => {
        gon.features.deprecateVulnerabilitiesFeedback = false;
        mutations[types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS](state, {
          vulnerability: state.vulnerabilities[0],
          data,
        });
      });

      it('should set the dismissal feedback on the passed vulnerability', () => {
        expect(state.vulnerabilities[0].dismissal_feedback).toEqual(data);
      });

      it('should set isDismissingVulnerability to false', () => {
        expect(state.isDismissingVulnerability).toBe(false);
      });

      it('should set isDismissed on the modal vulnerability to be true', () => {
        expect(state.modal.vulnerability.isDismissed).toBe(true);
      });
    });
  });

  describe('RECEIVE_ADD_DISMISSAL_COMMENT_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR](state);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(state.isDismissingVulnerability).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(state.modal.error).toBe('There was an error adding the comment.');
    });
  });

  describe('REQUEST_REVERT_DISMISSAL', () => {
    beforeEach(() => {
      mutations[types.REQUEST_REVERT_DISMISSAL](state);
    });

    it('should set isDismissingVulnerability to true', () => {
      expect(state.isDismissingVulnerability).toBe(true);
    });

    it('should nullify the error state on the modal', () => {
      expect(state.modal.error).toBeNull();
    });
  });

  describe('RECEIVE_REVERT_DISMISSAL_SUCCESS', () => {
    let vulnerability;
    const detectedTransition = { toState: 'DETECTED' };

    beforeEach(() => {
      state.vulnerabilities = mockData;
      [vulnerability] = mockData;
    });

    describe('deprecateVulnerabilitiesFeedback feature flag enabled', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_REVERT_DISMISSAL_SUCCESS](state, {
          vulnerability,
          data: {
            securityFindingRevertToDetected: {
              securityFinding: {
                vulnerability: {
                  stateTransitions: { nodes: [detectedTransition] },
                },
              },
            },
          },
        });
      });

      it('should set state and state_transitions on the passed vulnerability', () => {
        expect(vulnerability.state).toEqual(detectedTransition.toState.toLowerCase());
        expect(vulnerability.state_transitions).toEqual([
          convertObjectPropsToSnakeCase(detectedTransition),
        ]);
      });

      it('should set isDismissingVulnerability to false', () => {
        expect(state.isDismissingVulnerability).toBe(false);
      });

      it('should set isDismissed on the modal vulnerability to be false', () => {
        expect(state.modal.vulnerability.isDismissed).toBe(false);
      });
    });

    describe('deprecateVulnerabilitiesFeedback feature flag disabled', () => {
      beforeEach(() => {
        gon.features = { deprecateVulnerabilitiesFeedback: false };
        mutations[types.RECEIVE_REVERT_DISMISSAL_SUCCESS](state, { vulnerability });
      });

      it('should set the dismissal feedback on the passed vulnerability', () => {
        expect(vulnerability.dismissal_feedback).toBeNull();
      });

      it('should set isDismissingVulnerability to false', () => {
        expect(state.isDismissingVulnerability).toBe(false);
      });

      it('should set isDismissed on the modal vulnerability to be false', () => {
        expect(state.modal.vulnerability.isDismissed).toBe(false);
      });
    });
  });

  describe('RECEIVE_REVERT_DISMISSAL_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_REVERT_DISMISSAL_ERROR](state);
    });

    it('should set isDismissingVulnerability to false', () => {
      expect(state.isDismissingVulnerability).toBe(false);
    });

    it('should set the error state on the modal', () => {
      expect(state.modal.error).toBe('There was an error reverting the dismissal.');
    });
  });

  describe('OPEN_DISMISSAL_COMMENT_BOX', () => {
    beforeEach(() => {
      mutations[types.OPEN_DISMISSAL_COMMENT_BOX](state);
    });

    it('should set isCommentingOnDismissal to true', () => {
      expect(state.modal.isCommentingOnDismissal).toBe(true);
    });
  });

  describe('CLOSE_DISMISSAL_COMMENT_BOX', () => {
    beforeEach(() => {
      mutations[types.CLOSE_DISMISSAL_COMMENT_BOX](state);
    });

    it('should set isCommentingOnDismissal to false', () => {
      expect(state.modal.isCommentingOnDismissal).toBe(false);
    });

    it('should set isShowingDeleteButtons to false', () => {
      expect(state.modal.isShowingDeleteButtons).toBe(false);
    });
  });
});
