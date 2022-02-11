import { TEST_HOST } from 'helpers/test_constants';

const createIssue = (values) => {
  return {
    state: 'closed',
    epic: {
      iid: 12345,
    },
    labels: [],
    milestone: {
      title: '11.1',
    },
    weight: '3',
    due_date: '2020-10-08',
    assignees: [],
    author: {},
    web_url: `issues/${values.id}`,
    iid: values.id,
    ...values,
  };
};

export const mockIssuesApiResponse = [
  createIssue({ id: 12345, title: 'Issue 1', created_at: '2020-01-08' }),
  createIssue({ id: 23456, title: 'Issue 2', created_at: '2020-01-07' }),
  createIssue({ id: 34567, title: 'Issue 3', created_at: '2020-01-6' }),
];

export const tableHeaders = [
  'Issue',
  'Age',
  'Status',
  'Milestone',
  'Weight',
  'Due date',
  'Assignees',
  'Created by',
];

export const endpoints = {
  api: `${TEST_HOST}/api`,
  issuesPage: `${TEST_HOST}/issues/page`,
};
