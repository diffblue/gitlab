import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import LoadingError from 'ee/security_dashboard/components/pipeline/loading_error.vue';
import SecurityDashboardTable from 'ee/security_dashboard/components/pipeline/security_dashboard_table.vue';
import SecurityDashboard from 'ee/security_dashboard/components/pipeline/security_dashboard_vuex.vue';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { BV_HIDE_MODAL } from '~/lib/utils/constants';
import {
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_UNAUTHORIZED,
} from '~/lib/utils/http_status';

Vue.use(Vuex);

const projectId = 5678;
const sourceBranch = 'feature-branch-1';
const jobsPath = 'my-jobs-path';
const pipelineId = 123;
const pipelineIid = 12;
const vulnerabilitiesEndpoint = `${TEST_HOST}/vulnerabilities`;

jest.mock('~/flash');

describe('Security Dashboard component', () => {
  let wrapper;
  let mock;
  let store;

  const createComponent = ({ props } = {}) => {
    store = new Vuex.Store();
    jest.spyOn(store, 'dispatch');

    wrapper = shallowMount(SecurityDashboard, {
      store,
      provide: {
        projectId,
        projectFullPath: 'my-path',
        pipeline: {
          id: pipelineId,
          iid: pipelineIid,
          jobsPath,
          sourceBranch,
        },
        vulnerabilitiesEndpoint,
      },
      propsData: {
        projectFullPath: '/path',
        vulnerabilitiesEndpoint,
        pipelineId,
        pipelineIid,
        ...props,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mock.restore();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the security dashboard table', () => {
      expect(wrapper.findComponent(SecurityDashboardTable).exists()).toBe(true);
    });

    it('sets the source branch', () => {
      expect(store.dispatch).toHaveBeenCalledWith('vulnerabilities/setSourceBranch', sourceBranch);
    });

    it('sets the pipeline jobs path', () => {
      expect(store.dispatch).toHaveBeenCalledWith('pipelineJobs/setPipelineJobsPath', jobsPath);
    });

    it('sets the project id', () => {
      expect(store.dispatch).toHaveBeenCalledWith('pipelineJobs/setProjectId', projectId);
    });

    it('sets the pipeline id', () => {
      expect(store.dispatch).toHaveBeenCalledWith('vulnerabilities/setPipelineId', pipelineId);
    });

    it('fetches the pipeline jobs', () => {
      expect(store.dispatch).toHaveBeenCalledWith('pipelineJobs/fetchPipelineJobs', undefined);
    });

    it('renders the issue modal', () => {
      expect(wrapper.findComponent(IssueModal).exists()).toBe(true);
    });

    it.each`
      emittedModalEvent                      | eventPayload | expectedDispatchedAction                        | expectedActionPayload
      ${'addDismissalComment'}               | ${'foo'}     | ${'vulnerabilities/addDismissalComment'}        | ${{ comment: 'foo', vulnerability: 'bar' }}
      ${'editVulnerabilityDismissalComment'} | ${undefined} | ${'vulnerabilities/openDismissalCommentBox'}    | ${undefined}
      ${'showDismissalDeleteButtons'}        | ${undefined} | ${'vulnerabilities/showDismissalDeleteButtons'} | ${undefined}
      ${'hideDismissalDeleteButtons'}        | ${undefined} | ${'vulnerabilities/hideDismissalDeleteButtons'} | ${undefined}
      ${'deleteDismissalComment'}            | ${undefined} | ${'vulnerabilities/deleteDismissalComment'}     | ${{ vulnerability: 'bar' }}
      ${'closeDismissalCommentBox'}          | ${undefined} | ${'vulnerabilities/closeDismissalCommentBox'}   | ${undefined}
      ${'createMergeRequest'}                | ${undefined} | ${'vulnerabilities/createMergeRequest'}         | ${{ vulnerability: 'bar' }}
      ${'createNewIssue'}                    | ${undefined} | ${'vulnerabilities/createIssue'}                | ${{ vulnerability: 'bar' }}
      ${'dismissVulnerability'}              | ${'bar'}     | ${'vulnerabilities/dismissVulnerability'}       | ${{ comment: 'bar', vulnerability: 'bar' }}
      ${'openDismissalCommentBox'}           | ${undefined} | ${'vulnerabilities/openDismissalCommentBox'}    | ${undefined}
      ${'revertDismissVulnerability'}        | ${undefined} | ${'vulnerabilities/revertDismissVulnerability'} | ${{ vulnerability: 'bar' }}
      ${'downloadPatch'}                     | ${undefined} | ${'vulnerabilities/downloadPatch'}              | ${{ vulnerability: 'bar' }}
    `(
      'dispatches the "$expectedDispatchedAction" action when the modal emits a "$emittedModalEvent" event',
      ({ emittedModalEvent, eventPayload, expectedDispatchedAction, expectedActionPayload }) => {
        store.state.vulnerabilities.modal.vulnerability = 'bar';

        jest.spyOn(store, 'dispatch').mockImplementation(() => Promise.resolve());
        wrapper.findComponent(IssueModal).vm.$emit(emittedModalEvent, eventPayload);

        expect(store.dispatch).toHaveBeenCalledWith(
          expectedDispatchedAction,
          expectedActionPayload,
        );
      },
    );

    it('emits a hide modal event when modal does not have an error and hideModal is called', async () => {
      const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');
      wrapper.vm.hideModal();
      expect(rootEmit).toHaveBeenCalledWith(BV_HIDE_MODAL, VULNERABILITY_MODAL_ID);
    });
  });

  describe('issue modal', () => {
    it.each`
      givenState                                                                                   | expectedProps
      ${{ modal: { vulnerability: 'foo' } }}                                                       | ${{ modal: { vulnerability: 'foo' }, canCreateIssue: false, canCreateMergeRequest: false, canDismissVulnerability: false, isCreatingIssue: false, isDismissingVulnerability: false, isCreatingMergeRequest: false }}
      ${{ modal: { vulnerability: { create_vulnerability_feedback_issue_path: 'foo' } } }}         | ${expect.objectContaining({ canCreateIssue: true })}
      ${{ modal: { vulnerability: { create_jira_issue_url: 'foo' } } }}                            | ${expect.objectContaining({ canCreateIssue: true })}
      ${{ modal: { vulnerability: { create_vulnerability_feedback_merge_request_path: 'foo' } } }} | ${expect.objectContaining({ canCreateMergeRequest: true })}
      ${{ modal: { vulnerability: { create_vulnerability_feedback_dismissal_path: 'foo' } } }}     | ${expect.objectContaining({ canDismissVulnerability: true })}
      ${{ isCreatingIssue: true }}                                                                 | ${expect.objectContaining({ isCreatingIssue: true })}
      ${{ isDismissingVulnerability: true }}                                                       | ${expect.objectContaining({ isDismissingVulnerability: true })}
      ${{ isCreatingMergeRequest: true }}                                                          | ${expect.objectContaining({ isCreatingMergeRequest: true })}
    `(
      'passes right props to issue modal with state $givenState',
      async ({ givenState, expectedProps }) => {
        createComponent();
        Object.assign(store.state.vulnerabilities, givenState);
        await nextTick();

        expect(wrapper.findComponent(IssueModal).props()).toStrictEqual(expectedProps);
      },
    );
  });

  describe('on error', () => {
    beforeEach(() => {
      createComponent();
      store.dispatch('vulnerabilities/receiveDismissVulnerabilityError', {
        flashError: 'Something went wrong',
      });
    });

    it('does not emit a hide modal event when modal has error', () => {
      const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');
      wrapper.vm.hideModal();
      expect(rootEmit).not.toHaveBeenCalled();
    });

    it.each([HTTP_STATUS_UNAUTHORIZED, HTTP_STATUS_FORBIDDEN])(
      'displays an error on error %s',
      async (errorCode) => {
        store.dispatch('vulnerabilities/receiveVulnerabilitiesError', errorCode);
        await nextTick();
        expect(wrapper.findComponent(LoadingError).exists()).toBe(true);
      },
    );

    it.each([HTTP_STATUS_NOT_FOUND, HTTP_STATUS_INTERNAL_SERVER_ERROR])(
      'does not display an error on error %s',
      async (errorCode) => {
        store.dispatch('vulnerabilities/receiveVulnerabilitiesError', errorCode);
        await nextTick();
        expect(wrapper.findComponent(LoadingError).exists()).toBe(false);
      },
    );
  });
});
