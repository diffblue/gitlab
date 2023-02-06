import MockAdapter from 'axios-mock-adapter';
import createApolloProvider from 'ee/external_issues_list/graphql';
import getExternalIssues from 'ee/integrations/zentao/issues_list/graphql/queries/get_zentao_issues.query.graphql';
import { externalIssuesResolverFactory } from 'ee/external_issues_list/graphql/resolver';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import { i18n } from '~/issues/list/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { mockExternalIssues } from '../mock_data';

const DEFAULT_ISSUES_FETCH_PATH = '/test/issues/fetch';
const DEFAULT_VARIABLES = {
  issuesFetchPath: DEFAULT_ISSUES_FETCH_PATH,
  search: '',
  labels: '',
  sort: '',
  state: '',
  page: 1,
};

const TEST_ERROR_RESPONSE = { errors: ['lorem ipsum'] };
const TEST_PAGE_HEADERS = {
  'x-page': '10',
  'x-total': '13',
};

const issueTrackerName = 'ZenTao';
const TYPE_EXTERNAL_ISSUES = `${issueTrackerName}Issues`;
const externalIssuesResolver = externalIssuesResolverFactory(issueTrackerName);

describe('ee/external_issues_list/graphql/resolvers', () => {
  let mock;
  let apolloClient;
  let issuesApiSpy;

  const createPageInfo = ({ page, total }) => ({
    __typename: `${TYPE_EXTERNAL_ISSUES}PageInfo`,
    page,
    total,
  });

  const createUserCore = ({ avatar_url: avatarUrl, web_url: webUrl, ...props }) => ({
    __typename: 'UserCore',
    avatarUrl,
    webUrl,
    ...props,
  });

  const createLabel = ({ text_color: textColor, ...props }) => ({
    __typename: 'Label',
    textColor,
    ...props,
  });

  const createExternalIssue = ({
    assignees,
    author,
    labels,
    closed_at: closedAt,
    created_at: createdAt,
    gitlab_web_url: gitlabWebUrl,
    updated_at: updatedAt,
    web_url: webUrl,
    project_id: projectId,
    ...props
  }) => ({
    __typename: `${issueTrackerName}Issue`,
    assignees: assignees.map(createUserCore),
    author: createUserCore(author),
    labels: labels.map(createLabel),
    closedAt,
    createdAt,
    gitlabWebUrl,
    updatedAt,
    webUrl,
    projectId,
    ...props,
  });

  const query = (variables = {}) =>
    apolloClient.query({
      variables: {
        ...DEFAULT_VARIABLES,
        ...variables,
      },
      query: getExternalIssues,
    });

  beforeEach(() => {
    issuesApiSpy = jest.fn();

    mock = new MockAdapter(axios);
    mock.onGet(DEFAULT_ISSUES_FETCH_PATH).reply((...args) => issuesApiSpy(...args));

    ({ defaultClient: apolloClient } = createApolloProvider(externalIssuesResolver));
  });

  afterEach(() => {
    mock.restore();
  });

  describe.each`
    desc                                           | errorResponse          | expectedErrors
    ${'when api request fails with data.errors'}   | ${TEST_ERROR_RESPONSE} | ${TEST_ERROR_RESPONSE.errors}
    ${'when api request fails with unknown erorr'} | ${{}}                  | ${[i18n.errorFetchingIssues]}
  `('$desc', ({ errorResponse, expectedErrors }) => {
    beforeEach(() => {
      issuesApiSpy.mockReturnValue([HTTP_STATUS_BAD_REQUEST, errorResponse]);
    });

    it('returns error data', async () => {
      const response = await query();

      expect(response.data).toEqual({
        externalIssues: {
          __typename: TYPE_EXTERNAL_ISSUES,
          errors: expectedErrors,
          pageInfo: createPageInfo({ page: 1, total: 0 }),
          nodes: [],
        },
      });
    });
  });

  describe('with successful api request', () => {
    beforeEach(() => {
      issuesApiSpy.mockReturnValue([HTTP_STATUS_OK, mockExternalIssues, TEST_PAGE_HEADERS]);
    });

    it('sends expected params', async () => {
      const variables = {
        search: 'test search',
        page: 5,
        state: 'test state',
        sort: 'test sort',
        labels: 'test labels',
      };

      expect(issuesApiSpy).not.toHaveBeenCalled();

      await query(variables);

      expect(issuesApiSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          params: {
            limit: DEFAULT_PAGE_SIZE,
            ...variables,
          },
        }),
      );
    });

    it('returns transformed data', async () => {
      const response = await query();

      expect(response.data).toEqual({
        externalIssues: {
          __typename: TYPE_EXTERNAL_ISSUES,
          errors: [],
          pageInfo: createPageInfo({ page: 10, total: 13 }),
          nodes: mockExternalIssues.map(createExternalIssue),
        },
      });
    });
  });
});
