import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import { i18n } from '~/issues/list/constants';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

/**
 * Generating external issues resolver with tracker name
 * @param {string} issueTrackerName the name of external issue
 */
export const externalIssuesResolverFactory = (issueTrackerName) => {
  const transformExternalIssueAssignees = (externalIssue) => {
    return externalIssue.assignees.map((assignee) => ({
      __typename: 'UserCore',
      ...assignee,
    }));
  };

  const transformExternalIssueAuthor = (externalIssue, authorId) => {
    return {
      __typename: 'UserCore',
      ...externalIssue.author,
      id: authorId,
    };
  };

  const transformExternalIssueLabels = (externalIssue) => {
    return externalIssue.labels.map((label) => ({
      __typename: 'Label', // eslint-disable-line @gitlab/require-i18n-strings
      ...label,
    }));
  };

  const transformExternalIssuePageInfo = (responseHeaders = {}) => {
    return {
      __typename: `${issueTrackerName}IssuesPageInfo`,
      page: parseInt(responseHeaders['x-page'] ?? 1, 10),
      total: parseInt(responseHeaders['x-total'] ?? 0, 10),
    };
  };

  const transformExternalIssuesREST = (response) => {
    const { headers, data: externalIssues } = response;

    return {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      __typename: `${issueTrackerName}Issues`,
      errors: [],
      pageInfo: transformExternalIssuePageInfo(headers),
      nodes: externalIssues.map((rawIssue, index) => {
        const externalIssue = convertObjectPropsToCamelCase(rawIssue, { deep: true });
        return {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          __typename: `${issueTrackerName}Issue`,
          ...externalIssue,
          id: rawIssue.id,
          author: transformExternalIssueAuthor(externalIssue, index),
          labels: transformExternalIssueLabels(externalIssue),
          assignees: transformExternalIssueAssignees(externalIssue),
        };
      }),
    };
  };

  function IssuesResolver(_, { issuesFetchPath, search, page, state, sort, labels }) {
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
        return transformExternalIssuesREST(res);
      })
      .catch((error) => {
        return {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          __typename: `${issueTrackerName}Issues`,
          errors: error?.response?.data?.errors || [i18n.errorFetchingIssues],
          pageInfo: transformExternalIssuePageInfo(),
          nodes: [],
        };
      });
  }

  return IssuesResolver;
};
