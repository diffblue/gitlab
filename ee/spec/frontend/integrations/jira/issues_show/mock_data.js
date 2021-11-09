export const mockJiraIssue = {
  title: 'FE-2 The second FE issue on Jira',
  description_html:
    '<a href="https://jira.reali.sh:8080/projects/FE/issues/FE-2">FE-2</a> The second FE issue on Jira',
  created_at: '"2021-02-01T04:04:40.833Z"',
  author: {
    name: 'Justin Ho',
    web_url: 'http://127.0.0.1:3000/root',
    avatar_url: 'http://127.0.0.1:3000/uploads/-/system/user/avatar/1/avatar.png?width=90',
  },
  assignees: [
    {
      name: 'Justin Ho',
      web_url: 'http://127.0.0.1:3000/root',
      avatar_url: 'http://127.0.0.1:3000/uploads/-/system/user/avatar/1/avatar.png?width=90',
    },
  ],
  due_date: '2021-02-14T00:00:00.000Z',
  labels: [
    {
      title: 'In Progress',
      description: 'Work that is still in progress',
      color: '#0052CC',
      text_color: '#FFFFFF',
    },
  ],
  references: {
    relative: 'FE-2',
  },
  state: 'opened',
  status: 'In Progress',
};

export const mockJiraIssueComment = {
  body_html: '<p>hi</p>',
  created_at: '"2021-02-01T04:04:40.833Z"',
  author: {
    name: 'Justin Ho',
    web_url: 'http://127.0.0.1:3000/root',
    avatar_url: 'http://127.0.0.1:3000/uploads/-/system/user/avatar/1/avatar.png?width=90',
  },
  id: 10000,
};
