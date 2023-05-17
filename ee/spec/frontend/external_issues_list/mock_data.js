import jiraLogo from '@gitlab/svgs/dist/illustrations/logos/jira.svg?raw';
import mockGetJiraIssuesQuery from 'ee/integrations/jira/issues_list/graphql/queries/get_jira_issues.query.graphql';

export const mockProvide = {
  initialState: 'opened',
  initialSortBy: 'created_desc',
  page: 1,
  issuesFetchPath: '/gitlab-org/gitlab-test/-/integrations/jira/issues.json',
  projectFullPath: 'gitlab-org/gitlab-test',
  issueCreateUrl: 'https://gitlab-jira.atlassian.net/secure/CreateIssue!default.jspa',
  emptyStatePath: '/assets/illustrations/issues.svg',

  getIssuesQuery: mockGetJiraIssuesQuery,
  externalIssuesLogo: jiraLogo,
  externalIssueTrackerName: 'Jira',
  emptyStateNoIssueText:
    'Issues created in Jira are shown here once you have created the issues in project setup in Jira.',
  recentSearchesStorageKey: 'jira_issues',
  createNewIssueText: 'Create new issue in Jira',
  searchInputPlaceholderText: 'Search Jira issues',
};

export const mockJiraIssue1 = {
  project_id: 1,
  title: 'Eius fuga voluptates.',
  created_at: '2020-03-19T14:31:51.281Z',
  updated_at: '2020-10-20T07:01:45.865Z',
  closed_at: null,
  status: 'Selected for Development',
  labels: [
    {
      id: 'label-1',
      title: 'backend',
      name: 'backend',
      color: '#0052CC',
      text_color: '#FFFFFF',
    },
  ],
  author: {
    id: 'user-1',
    name: 'jhope',
    web_url: 'https://gitlab-jira.atlassian.net/people/5e32f803e127810e82875bc1',
    avatar_url: null,
  },
  assignees: [
    {
      id: 'user-2',
      name: 'Kushal Pandya',
      web_url: 'https://gitlab-jira.atlassian.net/people/1920938475',
      avatar_url: null,
    },
  ],
  web_url: 'https://gitlab-jira.atlassian.net/browse/IG-31596',
  gitlab_web_url: '',
  references: {
    relative: 'IG-31596',
  },
  external_tracker: 'jira',
};

export const mockJiraIssue2 = {
  project_id: 1,
  title: 'Hic sit sint ducimus ea et sint.',
  created_at: '2020-03-19T14:31:50.677Z',
  updated_at: '2020-03-19T14:31:50.677Z',
  closed_at: null,
  status: 'Backlog',
  labels: [],
  author: {
    id: 'user-3',
    name: 'Gabe Weaver',
    web_url: 'https://gitlab-jira.atlassian.net/people/5e320a31fe03e20c9d1dccde',
    avatar_url: null,
  },
  assignees: [],
  web_url: 'https://gitlab-jira.atlassian.net/browse/IG-31595',
  gitlab_web_url: '',
  references: {
    relative: 'IG-31595',
  },
  external_tracker: 'jira',
};

export const mockJiraIssue3 = {
  project_id: 1,
  title: 'Alias ut modi est labore.',
  created_at: '2020-03-19T14:31:50.012Z',
  updated_at: '2020-03-19T14:31:50.012Z',
  closed_at: null,
  status: 'Backlog',
  labels: [],
  author: {
    id: 'user-3',
    name: 'Gabe Weaver',
    web_url: 'https://gitlab-jira.atlassian.net/people/5e320a31fe03e20c9d1dccde',
    avatar_url: null,
  },
  assignees: [],
  web_url: 'https://gitlab-jira.atlassian.net/browse/IG-31594',
  gitlab_web_url: '',
  references: {
    relative: 'IG-31594',
  },
  external_tracker: 'jira',
};

// issue without reference presence
export const mockJiraIssue4 = {
  project_id: 1,
  title: 'Alias ut modi est labore.',
  created_at: '2020-03-19T14:31:50.012Z',
  updated_at: '2020-03-19T14:31:50.012Z',
  closed_at: null,
  status: 'Backlog',
  labels: [],
  author: {
    id: 'user-3',
    name: 'Gabe Weaver',
    web_url: 'https://gitlab-jira.atlassian.net/people/5e320a31fe03e20c9d1dccde',
    avatar_url: null,
  },
  assignees: [],
  web_url: 'https://gitlab-jira.atlassian.net/browse/IG-31594',
  gitlab_web_url: '',
  external_tracker: 'jira',
};

export const mockJiraIssues = [mockJiraIssue1, mockJiraIssue2, mockJiraIssue3];

export const mockZentaoIssue = {
  project_id: 1,
  id: 3,
  title: 'Alias ut modi est labore.',
  created_at: '2020-03-19T14:31:50.012Z',
  updated_at: '2020-03-19T14:31:50.012Z',
  closed_at: null,
  status: 'Backlog',
  labels: [],
  author: {
    id: 0,
    name: 'Gabe Weaver',
    web_url: 'https://gitlab-zentao.atlassian.net/people/5e320a31fe03e20c9d1dccde',
    avatar_url: null,
  },
  assignees: [],
  web_url: 'https://gitlab-zentao.atlassian.net/browse/IG-31594',
  gitlab_web_url: '',
};

export const mockExternalIssues = [mockZentaoIssue];
