import { shallowMount, createWrapper } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import LoadingError from 'ee/security_dashboard/components/pipeline/loading_error.vue';
import SecurityDashboardTable from 'ee/security_dashboard/components/pipeline/security_dashboard_table.vue';
import SecurityDashboard from 'ee/security_dashboard/components/pipeline/security_dashboard_vuex.vue';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import VulnerabilityFindingModal from 'ee/security_dashboard/components/pipeline/vulnerability_finding_modal.vue';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { BV_HIDE_MODAL, BV_SHOW_MODAL } from '~/lib/utils/constants';
import {
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_UNAUTHORIZED,
} from '~/lib/utils/http_status';

Vue.use(Vuex);

const projectId = 5678;
const projectFullPath = 'my-path';
const sourceBranch = 'feature-branch-1';
const jobsPath = 'my-jobs-path';
const pipelineId = 123;
const pipelineIid = 12;
const vulnerabilitiesEndpoint = `${TEST_HOST}/vulnerabilities`;

jest.mock('~/alert');

describe('Security Dashboard component', () => {
  let wrapper;
  let mock;
  let store;

  const createComponent = ({ props, provide } = {}) => {
    store = new Vuex.Store();
    jest.spyOn(store, 'dispatch');

    wrapper = shallowMount(SecurityDashboard, {
      store,
      provide: {
        projectId,
        projectFullPath,
        pipeline: {
          id: pipelineId,
          iid: pipelineIid,
          jobsPath,
          sourceBranch,
        },
        vulnerabilitiesEndpoint,
        ...provide,
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

    describe('finding modal', () => {
      const findingUuid = '1';

      const openFindingModal = async () => {
        Object.assign(store.state.vulnerabilities, {
          modal: { vulnerability: { uuid: findingUuid } },
        });
        const rootWrapper = createWrapper(wrapper.vm.$root);
        rootWrapper.vm.$emit(BV_SHOW_MODAL, VULNERABILITY_MODAL_ID);
        await nextTick();
      };

      beforeEach(openFindingModal);

      it('passes the correct props to the finding modal', () => {
        expect(wrapper.findComponent(VulnerabilityFindingModal).props()).toMatchObject({
          findingUuid,
          pipelineIid,
          projectFullPath,
        });
      });

      it('gets closed when "hidden" is emitted', async () => {
        expect(wrapper.findComponent(VulnerabilityFindingModal).exists()).toBe(true);

        wrapper.findComponent(VulnerabilityFindingModal).vm.$emit('hidden');
        await nextTick();

        expect(wrapper.findComponent(VulnerabilityFindingModal).exists()).toBe(false);
      });

      it.each`
        description                                                         | eventName      | expectedPayload
        ${'re-fetches the vulnerability list'}                              | ${'dismissed'} | ${{ vulnerability: { uuid: findingUuid } }}
        ${'re-fetches the vulnerability list without show a toast message'} | ${'detected'}  | ${{ vulnerability: { uuid: findingUuid }, showToast: false }}
      `('$description when "$eventName" is emitted', ({ eventName, expectedPayload }) => {
        jest.spyOn(store, 'dispatch').mockImplementation(() => Promise.resolve());

        wrapper.findComponent(VulnerabilityFindingModal).vm.$emit(eventName);

        expect(store.dispatch).toHaveBeenLastCalledWith(
          'vulnerabilities/reFetchVulnerabilitiesAfterDismissal',
          expectedPayload,
        );
      });
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      createComponent();
      store.dispatch('vulnerabilities/receiveDismissVulnerabilityError', {
        flashError: 'Something went wrong',
      });
    });

    it('does not emit a hide modal event when modal has error', () => {
      const rootWrapper = createWrapper(wrapper.vm.$root);

      expect(wrapper.findComponent(VulnerabilityFindingModal).exists()).toBe(false);
      expect(rootWrapper.emitted(BV_HIDE_MODAL)).toBeUndefined();
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
