import MockAdapter from 'axios-mock-adapter';
import createApolloProvider from 'ee/external_issues_list/graphql';
import getZentaoIssues from 'ee/integrations/zentao/issues_list/graphql/queries/get_zentao_issues.query.graphql';
import zentaoIssuesResolver from 'ee/integrations/zentao/issues_list/graphql/resolvers/zentao_issues';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import { i18n } from '~/issues/list/constants';
import axios from '~/lib/utils/axios_utils';
import { mockZentaoIssues } from '../mock_data';

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

const TYPE_ZENTAO_ISSUES = 'ZentaoIssues';

describe('ee/integrations/zentao/issues_list/graphql/resolvers/zentao_issues', () => {
  let mock;
  let apolloClient;
  let issuesApiSpy;

  const createPageInfo = ({ page, total }) => ({
    __typename: 'ZentaoIssuesPageInfo',
    page,
    total,
  });

  const createUserCore = ({ avatar_url, web_url, ...props }) => ({
    __typename: 'UserCore',
    avatarUrl: avatar_url,
    webUrl: web_url,
    ...props,
  });

  const createLabel = ({ text_color, ...props }) => ({
    __typename: 'Label',
    textColor: text_color,
    ...props,
  });

  const createZentaoIssue = ({
    assignees,
    author,
    labels,
    closed_at,
    created_at,
    gitlab_web_url,
    updated_at,
    web_url,
    project_id,
    ...props
  }) => ({
    __typename: 'ZentaoIssue',
    assignees: assignees.map(createUserCore),
    author: createUserCore(author),
    labels: labels.map(createLabel),
    closedAt: closed_at,
    createdAt: created_at,
    gitlabWebUrl: gitlab_web_url,
    updatedAt: updated_at,
    webUrl: web_url,
    projectId: project_id,
    ...props,
  });

  const query = (variables = {}) =>
    apolloClient.query({
      variables: {
        ...DEFAULT_VARIABLES,
        ...variables,
      },
      query: getZentaoIssues,
    });

  beforeEach(() => {
    issuesApiSpy = jest.fn();

    mock = new MockAdapter(axios);
    mock.onGet(DEFAULT_ISSUES_FETCH_PATH).reply((...args) => issuesApiSpy(...args));

    ({ defaultClient: apolloClient } = createApolloProvider(zentaoIssuesResolver));
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
      issuesApiSpy.mockReturnValue([400, errorResponse]);
    });

    it('returns error data', async () => {
      const response = await query();

      expect(response.data).toEqual({
        externalIssues: {
          __typename: TYPE_ZENTAO_ISSUES,
          errors: expectedErrors,
          pageInfo: createPageInfo({ page: Number.NaN, total: Number.NaN }),
          nodes: [],
        },
      });
    });
  });

  describe('with successful api request', () => {
    beforeEach(() => {
      issuesApiSpy.mockReturnValue([200, mockZentaoIssues, TEST_PAGE_HEADERS]);
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
          __typename: TYPE_ZENTAO_ISSUES,
          errors: [],
          pageInfo: createPageInfo({ page: 10, total: 13 }),
          nodes: mockZentaoIssues.map(createZentaoIssue),
        },
      });
    });
  });
});
