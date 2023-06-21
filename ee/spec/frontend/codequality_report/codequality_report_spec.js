import { GlInfiniteScroll } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import ReportSection from '~/ci/reports/components/report_section.vue';
import getCodeQualityViolations from 'ee/codequality_report/graphql/queries/get_code_quality_violations.query.graphql';
import { LOADING, ERROR, SUCCESS } from '~/ci/reports/constants';
import { mockGetCodeQualityViolationsResponse, codeQualityViolations } from './mock_data';

Vue.use(VueApollo);

describe('Codequality report app', () => {
  let wrapper;

  const createComponent = (
    mockReturnValue = jest.fn().mockResolvedValue(mockGetCodeQualityViolationsResponse),
  ) => {
    const apolloProvider = createMockApollo([[getCodeQualityViolations, mockReturnValue]]);

    wrapper = shallowMount(CodequalityReportApp, {
      apolloProvider,
      provide: {
        projectPath: 'project-path',
        pipelineIid: 'pipeline-iid',
        blobPath: '/blob/path',
      },
      stubs: {
        ReportSection: stubComponent(ReportSection, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  const findReportSection = () => wrapper.findComponent(ReportSection);
  const findInfiniteScroll = () => wrapper.findComponent(GlInfiniteScroll);

  describe('when loading', () => {
    beforeEach(() => {
      createComponent(jest.fn().mockReturnValueOnce(new Promise(() => {})));
    });

    it('shows a loading state', () => {
      expect(findReportSection().props().status).toBe(LOADING);
    });
  });

  describe('on error', () => {
    beforeEach(async () => {
      createComponent(jest.fn().mockRejectedValueOnce(new Error('Error!')));
      await waitForPromises();
    });

    it('shows error message', () => {
      expect(findReportSection().props().status).toBe(ERROR);
      expect(findReportSection().props().errorText).toBe('Failed to load Code Quality report');
    });
  });

  describe('when there are codequality issues', () => {
    beforeEach(async () => {
      createComponent(jest.fn().mockResolvedValue(mockGetCodeQualityViolationsResponse));
      await waitForPromises();
    });

    it('renders the codequality issues', () => {
      const expectedIssueTotal = codeQualityViolations.count;

      expect(findReportSection().props().status).toBe(SUCCESS);
      expect(findInfiniteScroll().exists()).toBe(true);
      expect(findReportSection().props().successText).toBe(
        `Found ${expectedIssueTotal} code quality issues`,
      );
      expect(findReportSection().props().unresolvedIssues).toHaveLength(expectedIssueTotal);
    });

    it('loads the next page when the end of the list is reached', async () => {
      const expectedIssueTotal = codeQualityViolations.count * 2;
      findInfiniteScroll().vm.$emit('bottomReached');

      await waitForPromises();

      expect(findReportSection().props().unresolvedIssues).toHaveLength(expectedIssueTotal);
    });
  });

  describe('when the endcursor is null', () => {
    beforeEach(async () => {
      const endOfListResponse = {
        data: {
          project: {
            id: '1',
            pipeline: {
              id: 'pipeline-1',
              codeQualityReports: {
                ...codeQualityViolations,
                pageInfo: {
                  hasNextPage: false,
                  hasPreviousPage: true,
                  startCursor: null,
                  endCursor: null,
                  __typename: 'PageInfo',
                },
              },
            },
          },
        },
      };

      createComponent(jest.fn().mockResolvedValue(endOfListResponse));
      await waitForPromises();
    });

    it('stops adding listitems', async () => {
      expect(findReportSection().props().unresolvedIssues).toHaveLength(
        codeQualityViolations.count,
      );
      findInfiniteScroll().vm.$emit('bottomReached');
      await waitForPromises();
      expect(findReportSection().props().unresolvedIssues).toHaveLength(
        codeQualityViolations.count,
      );
    });
  });

  describe('when there are no codequality issues', () => {
    beforeEach(async () => {
      const emptyResponse = {
        data: {
          project: {
            id: '1',
            pipeline: {
              id: 'pipeline-1',
              codeQualityReports: {
                ...codeQualityViolations,
                nodes: [],
                count: 0,
              },
            },
          },
        },
      };

      createComponent(jest.fn().mockResolvedValue(emptyResponse));
      await waitForPromises();
    });

    it('shows a message that no codequality issues were found', () => {
      expect(findReportSection().props().status).toBe(SUCCESS);
      expect(findReportSection().props().successText).toBe('No code quality issues found');
      expect(findReportSection().props().unresolvedIssues).toHaveLength(0);
    });
  });
});
