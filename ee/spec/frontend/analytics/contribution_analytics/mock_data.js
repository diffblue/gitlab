export const MOCK_CONTRIBUTIONS = [
  {
    repoPushed: 0,
    mergeRequestsCreated: 234,
    mergeRequestsMerged: 35,
    mergeRequestsClosed: 75,
    mergeRequestsApproved: 15,
    issuesCreated: 75,
    issuesClosed: 34,
    totalEvents: 112,
    user: {
      id: 'spongebob',
      name: 'Spongebob',
      webUrl: 'http://bikini.bottom/spongebob',
    },
  },
  {
    repoPushed: 12,
    mergeRequestsCreated: 0,
    mergeRequestsMerged: 0,
    mergeRequestsClosed: 0,
    mergeRequestsApproved: 0,
    issuesCreated: 55,
    issuesClosed: 57,
    totalEvents: 37,
    user: {
      id: 'patrick',
      name: 'Patrick',
      webUrl: 'http://bikini.bottom/patrick',
    },
  },
  {
    repoPushed: 47,
    mergeRequestsCreated: 0,
    mergeRequestsMerged: 15,
    mergeRequestsClosed: 99,
    mergeRequestsApproved: 125,
    issuesCreated: 0,
    issuesClosed: 0,
    totalEvents: 1001,
    user: {
      id: 'krabs',
      name: 'Mr Krabs',
      webUrl: 'http://bikini.bottom/krabs',
    },
  },
];

export const MOCK_PUSHES = [
  { count: 15, user: 'luffy' },
  { count: 19, user: 'zoro' },
  { count: 21, user: 'nami' },
];

export const MOCK_MERGE_REQUESTS = [
  { created: 5, closed: 7, merged: 4, user: 'luffy' },
  { created: 9, closed: 2, merged: 7, user: 'zoro' },
  { created: 17, closed: 27, merged: 21, user: 'nami' },
];

export const MOCK_ISSUES = [
  { created: 5, closed: 7, user: 'luffy' },
  { created: 9, closed: 2, user: 'zoro' },
  { created: 17, closed: 27, user: 'nami' },
];
