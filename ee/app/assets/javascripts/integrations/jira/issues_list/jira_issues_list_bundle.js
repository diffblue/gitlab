import jiraLogo from '@gitlab/svgs/dist/illustrations/logos/jira.svg?raw';
import externalIssuesListFactory from 'ee/external_issues_list';
import { s__ } from '~/locale';
import getIssuesQuery from './graphql/queries/get_jira_issues.query.graphql';
import jiraIssuesResolver from './graphql/resolvers/jira_issues';

export default externalIssuesListFactory({
  externalIssuesQueryResolver: jiraIssuesResolver,
  provides: {
    getIssuesQuery,
    externalIssuesLogo: jiraLogo,
    externalIssueTrackerName: 'Jira', // eslint-disable-line @gitlab/require-i18n-strings
    searchInputPlaceholderText: s__('Integrations|Search Jira issues'),
    recentSearchesStorageKey: 'jira_issues',
    createNewIssueText: s__('Integrations|Create new issue in Jira'),
    emptyStateNoIssueText: s__(
      'Integrations|Issues created in Jira are shown here once you have created the issues in project setup in Jira.',
    ),
  },
});
