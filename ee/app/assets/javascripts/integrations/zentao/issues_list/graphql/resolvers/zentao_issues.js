import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import { i18n } from '~/issues/list/constants';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const transformZentaoIssueAssignees = (zentaoIssue) => {
  return zentaoIssue.assignees.map((assignee) => ({
    __typename: 'UserCore',
    ...assignee,
  }));
};

const transformZentaoIssueAuthor = (zentaoIssue, authorId) => {
  return {
    __typename: 'UserCore',
    ...zentaoIssue.author,
    id: authorId,
  };
};

const transformZentaoIssueLabels = (zentaoIssue) => {
  return zentaoIssue.labels.map((label) => ({
    __typename: 'Label', // eslint-disable-line @gitlab/require-i18n-strings
    ...label,
  }));
};

const transformZentaoIssuePageInfo = (responseHeaders = {}) => {
  return {
    __typename: 'ZentaoIssuesPageInfo',
    page: parseInt(responseHeaders['x-page'], 10) ?? 1,
    total: parseInt(responseHeaders['x-total'], 10) ?? 0,
  };
};

export const transformZentaoIssuesREST = (response) => {
  const { headers, data: zentaoIssues } = response;

  return {
    __typename: 'ZentaoIssues',
    errors: [],
    pageInfo: transformZentaoIssuePageInfo(headers),
    nodes: zentaoIssues.map((rawIssue, index) => {
      const zentaoIssue = convertObjectPropsToCamelCase(rawIssue, { deep: true });
      return {
        __typename: 'ZentaoIssue',
        ...zentaoIssue,
        id: rawIssue.id,
        author: transformZentaoIssueAuthor(zentaoIssue, index),
        labels: transformZentaoIssueLabels(zentaoIssue),
        assignees: transformZentaoIssueAssignees(zentaoIssue),
      };
    }),
  };
};

export default function zentaoIssuesResolver(
  _,
  { issuesFetchPath, search, page, state, sort, labels },
) {
  return axios
    .get(issuesFetchPath, {
      params: {
        limit: DEFAULT_PAGE_SIZE,
        page,
        state,
        sort,
        labels,
        search,
      },
    })
    .then((res) => {
      return transformZentaoIssuesREST(res);
    })
    .catch((error) => {
      return {
        __typename: 'ZentaoIssues',
        errors: error?.response?.data?.errors || [i18n.errorFetchingIssues],
        pageInfo: transformZentaoIssuePageInfo(),
        nodes: [],
      };
    });
}
