import { GlInfiniteScroll } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import CodequalityReportApp from 'ee/codequality_report/codequality_report_graphql.vue';
import getCodeQualityViolations from 'ee/codequality_report/graphql/queries/get_code_quality_violations.query.graphql';
import { mockGetCodeQualityViolationsResponse, codeQualityViolations } from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Codequality report app', () => {
  let wrapper;

  const createComponent = (
    mockReturnValue = jest.fn().mockResolvedValue(mockGetCodeQualityViolationsResponse),
    mountFn = mount,
  ) => {
    const apolloProvider = createMockApollo([[getCodeQualityViolations, mockReturnValue]]);

    wrapper = mountFn(CodequalityReportApp, {
      localVue,
      apolloProvider,
      provide: {
        projectPath: 'project-path',
        pipelineIid: 'pipeline-iid',
        blobPath: '/blob/path',
      },
    });
  };

  const findStatus = () => wrapper.find('.js-code-text');
  const findSuccessIcon = () => wrapper.find('.js-ci-status-icon-success');
  const findWarningIcon = () => wrapper.find('.js-ci-status-icon-warning');
  const findInfiniteScroll = () => wrapper.findComponent(GlInfiniteScroll);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent(jest.fn().mockReturnValueOnce(new Promise(() => {})));
    });

    it('shows a loading state', () => {
      expect(findStatus().text()).toBe('Loading Code Quality report');
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      createComponent(jest.fn().mockRejectedValueOnce(new Error('Error!')));
    });

    it('shows a warning icon and error message', () => {
      expect(findWarningIcon().exists()).toBe(true);
      expect(findStatus().text()).toBe('Failed to load Code Quality report');
    });
  });

  describe('when there are codequality issues', () => {
    beforeEach(() => {
      createComponent(jest.fn().mockResolvedValue(mockGetCodeQualityViolationsResponse));
    });

    it('renders the codequality issues', () => {
      const expectedIssueTotal = codeQualityViolations.count;

      expect(findWarningIcon().exists()).toBe(true);
      expect(findInfiniteScroll().exists()).toBe(true);
      expect(findStatus().text()).toContain(`Found ${expectedIssueTotal} code quality issues`);
      expect(findStatus().text()).toContain(
        `This report contains all Code Quality issues in the source branch.`,
      );
      expect(wrapper.findAll('.report-block-list-issue')).toHaveLength(expectedIssueTotal);
    });

    it('renders a link to the line where the issue was found', () => {
      const issueLink = wrapper.find('.report-block-list-issue a');

      expect(issueLink.text()).toBe('foo.rb:10');
      expect(issueLink.attributes('href')).toBe('/blob/path/foo.rb#L10');
    });

    it('loads the next page when the end of the list is reached', async () => {
      jest
        .spyOn(wrapper.vm.$apollo.queries.codequalityViolations, 'fetchMore')
        .mockResolvedValue({});

      findInfiniteScroll().vm.$emit('bottomReached');

      await waitForPromises();

      expect(wrapper.vm.$apollo.queries.codequalityViolations.fetchMore).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: expect.objectContaining({
            after: codeQualityViolations.pageInfo.endCursor,
          }),
        }),
      );
    });
  });

  describe('when there are no codequality issues', () => {
    beforeEach(() => {
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
    });

    it('shows a message that no codequality issues were found', () => {
      expect(findSuccessIcon().exists()).toBe(true);
      expect(findStatus().text()).toBe('No code quality issues found');
      expect(wrapper.findAll('.report-block-list-issue')).toHaveLength(0);
    });
  });
});
