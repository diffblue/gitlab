import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { merge } from 'lodash';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import LoadingError from 'ee/security_dashboard/components/pipeline/loading_error.vue';
import SecurityDashboardTable from 'ee/security_dashboard/components/pipeline/security_dashboard_table.vue';
import SecurityDashboard from 'ee/security_dashboard/components/pipeline/security_dashboard_vuex.vue';
import { getStoreConfig } from 'ee/security_dashboard/store';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { BV_HIDE_MODAL } from '~/lib/utils/constants';

const pipelineId = 123;
const pipelineIid = 12;
const vulnerabilitiesEndpoint = `${TEST_HOST}/vulnerabilities`;

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterValues: jest.fn().mockReturnValue([]),
}));

jest.mock('~/flash');

describe('Security Dashboard component', () => {
  let wrapper;
  let mock;
  let setPipelineIdSpy;
  let fetchPipelineJobsSpy;
  let store;

  const createComponent = ({ props } = {}) => {
    setPipelineIdSpy = jest.fn();
    fetchPipelineJobsSpy = jest.fn();

    const { actions, ...storeConfig } = getStoreConfig();
    store = new Vuex.Store(
      merge(storeConfig, {
        modules: {
          vulnerabilities: { actions: { setPipelineId: setPipelineIdSpy } },
          pipelineJobs: { actions: { fetchPipelineJobs: fetchPipelineJobsSpy } },
        },
      }),
    );

    wrapper = shallowMount(SecurityDashboard, {
      store,
      propsData: {
        dashboardDocumentation: '',
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

    it('renders the security dashboard table ', () => {
      expect(wrapper.findComponent(SecurityDashboardTable).exists()).toBe(true);
    });

    it('sets the pipeline id', () => {
      expect(setPipelineIdSpy).toHaveBeenCalledWith(expect.any(Object), pipelineId);
    });

    it('fetchs the pipeline jobs', () => {
      expect(fetchPipelineJobsSpy).toHaveBeenCalledWith(expect.any(Object), undefined);
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

    it.each([401, 403])('displays an error on error %s', async (errorCode) => {
      store.dispatch('vulnerabilities/receiveVulnerabilitiesError', errorCode);
      await nextTick();
      expect(wrapper.findComponent(LoadingError).exists()).toBe(true);
    });

    it.each([404, 500])('does not display an error on error %s', async (errorCode) => {
      store.dispatch('vulnerabilities/receiveVulnerabilitiesError', errorCode);
      await nextTick();
      expect(wrapper.findComponent(LoadingError).exists()).toBe(false);
    });
  });
});
