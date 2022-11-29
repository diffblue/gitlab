export const approvedChecks = [
  {
    id: 1,
    name: 'Foo',
    external_url: 'http://foo',
    status: 'passed',
  },
];

export const pendingChecks = [
  {
    id: 2,
    name: 'Foo Bar',
    external_url: 'http://foobar',
    status: 'pending',
  },
];

export const failedChecks = [
  {
    id: 2,
    name: 'Oh no',
    external_url: 'http://noway',
    status: 'failed',
  },
];

export const pendingAndFailedChecks = [...pendingChecks, ...failedChecks];

export const approvedAndPendingChecks = [...approvedChecks, ...pendingChecks];

export const approvedFailedAndPending = [...approvedChecks, ...failedChecks, ...pendingChecks];
