import { GlAlert, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import PipelineFindings from 'ee/security_dashboard/components/pipeline/pipeline_findings.vue';
import FindingModal from 'ee/security_dashboard/components/pipeline/vulnerability_finding_modal.vue';
import VulnerabilityList from 'ee/security_dashboard/components/shared/vulnerability_list.vue';
import pipelineFindingsQuery from 'ee/security_dashboard/graphql/queries/pipeline_findings.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockPipelineFindingsResponse } from '../../mock_data';

describe('Pipeline findings', () => {
  let wrapper;

  const apolloMock = {
    queries: { findings: { loading: true } },
  };

  const createWrapper = ({ props = {}, mocks, apolloProvider } = {}) => {
    const localVue = createLocalVue();

    if (apolloProvider) {
      localVue.use(VueApollo);
    }

    wrapper = shallowMount(PipelineFindings, {
      localVue,
      apolloProvider,
      provide: {
        projectFullPath: 'gitlab/security-reports',
        pipeline: {
          id: 77,
          iid: 8,
        },
      },
      propsData: {
        filters: {},
        ...props,
      },
      mocks,
    });
  };

  const createWrapperWithApollo = (resolver) => {
    return createWrapper({
      apolloProvider: createMockApollo([[pipelineFindingsQuery, resolver]]),
    });
  };

  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findVulnerabilityList = () => wrapper.findComponent(VulnerabilityList);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findModal = () => wrapper.findComponent(FindingModal);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the findings are loading', () => {
    beforeEach(() => {
      createWrapper({ mocks: { $apollo: apolloMock } });
    });

    it('should show the initial loading state', () => {
      expect(findVulnerabilityList().props('isLoading')).toBe(true);
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('with findings', () => {
    beforeEach(() => {
      createWrapperWithApollo(jest.fn().mockResolvedValue(mockPipelineFindingsResponse()));
    });

    it('passes false as the loading state prop', () => {
      expect(findVulnerabilityList().props('isLoading')).toBe(false);
    });

    it('passes down findings', () => {
      expect(findVulnerabilityList().props('vulnerabilities')).toMatchObject([
        { confidence: 'unknown', id: '322ace94-2d2a-5efa-bd62-a04c927a4b9a', severity: 'HIGH' },
        { location: { file: 'package.json' }, id: '31ad79c6-b545-5408-89af-c4e90fc21eb4' },
      ]);
    });

    it('does not show the intersection loader when there is no next page', () => {
      expect(findIntersectionObserver().exists()).toBe(false);
    });

    describe('vulnerability finding modal', () => {
      it('is hidden per default', () => {
        expect(findModal().exists()).toBe(false);
      });

      it('is visible when a vulnerability is clicked', async () => {
        findVulnerabilityList().vm.$emit('vulnerability-clicked', {});
        await nextTick();

        expect(findModal().exists()).toBe(true);
      });

      it('gets passes the clicked finding as a prop', async () => {
        const vulnerability = {};

        findVulnerabilityList().vm.$emit('vulnerability-clicked', vulnerability);
        await nextTick();

        expect(findModal().props('finding')).toBe(vulnerability);
      });
    });
  });

  describe('with multiple page findings', () => {
    beforeEach(() => {
      createWrapperWithApollo(
        jest.fn().mockResolvedValue(mockPipelineFindingsResponse({ hasNextPage: true })),
      );
    });

    it('shows the intersection loader', () => {
      expect(findIntersectionObserver().exists()).toBe(true);
    });
  });

  describe('with failed query', () => {
    beforeEach(() => {
      createWrapperWithApollo(jest.fn().mockRejectedValue(new Error('GraphQL error')));
    });

    it('does not show the vulnerability list', () => {
      expect(findVulnerabilityList().exists()).toBe(false);
    });

    it('shows the error', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });
});
