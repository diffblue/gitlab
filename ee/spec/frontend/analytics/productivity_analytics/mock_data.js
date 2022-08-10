export const mockMergeRequests = [
  {
    id: 34,
    iid: 10,
    description: 'some descirption goes here',
    title: 'This is a test MR',
    days_to_merge: 24,
    time_to_first_comment: 596,
    time_to_last_commit: 0,
    time_to_merge: 0,
    commits_count: 1,
    loc_per_commit: 3,
    files_touched: 1,
    author_avatar_url: null,
    merge_request_url: 'http://gitlab.example.com/gitlab-org/gitlab-test/merge_requests/10',
  },
  {
    id: 6,
    iid: 6,
    description:
      'Error temporibus odit veniam expedita ipsa eum quia et. Quo deserunt accusamus ut est ab. Quia sit delectus possimus aut odio veritatis voluptatibus ullam.',
    title: 'Vero sint consectetur velit sit totam ipsa aut omnis non repellendus.',
    days_to_merge: 139,
    time_to_first_comment: 0,
    time_to_last_commit: -4530,
    time_to_merge: 7866,
    commits_count: 3,
    loc_per_commit: 4,
    files_touched: 3,
    author_avatar_url: null,
    merge_request_url: 'http://lgitlab.example.com/gitlab-org/gitlab-test/merge_requests/6',
  },
];

export const mockHistogramData = {
  1: 1,
  2: 2,
  3: 3,
  4: 4,
  5: 5,
  6: 6,
  7: 7,
  8: 8,
  9: 9,
  10: 10,
  11: 11,
  12: 12,
  13: 13,
  14: 14,
  15: 15,
  16: 16,
  17: 17,
  18: 18,
  19: 19,
  20: 20,
  21: 21,
  22: 22,
  23: 23,
  24: 24,
  25: 25,
  26: 26,
  27: 27,
  28: 28,
  29: 29,
  30: 30,
  31: 31,
  32: 32,
  33: 33,
  34: 34,
  35: 35,
  36: 36,
  37: 37,
  38: 38,
  39: 39,
  40: 40,
  41: 41,
};

export const mockScatterplotData = {
  1: {
    metric: 139,
    merged_at: '2019-08-18T22:00:00.000Z',
  },
  2: {
    metric: 138,
    merged_at: '2019-08-17T22:00:00.000Z',
  },
  3: {
    metric: 24,
    merged_at: '2019-08-16T22:00:00.000Z',
  },
  4: {
    metric: 56,
    merged_at: '2019-08-15T22:00:00.000Z',
  },
  5: {
    metric: 46,
    merged_at: '2019-08-14T22:00:00.000Z',
  },
  6: {
    metric: 43,
    merged_at: '2019-08-13T22:00:00.000Z',
  },
  7: {
    metric: 60,
    merged_at: '2019-08-12T22:00:00.000Z',
  },
  8: {
    metric: 62,
    merged_at: '2019-08-11T22:00:00.000Z',
  },
  9: {
    metric: 46,
    merged_at: '2019-08-10T22:00:00.000Z',
  },
  10: {
    metric: 44,
    merged_at: '2019-08-09T22:00:00.000Z',
  },
  11: {
    metric: 57,
    merged_at: '2019-08-08T22:00:00.000Z',
  },
  12: {
    metric: 51,
    merged_at: '2019-08-07T22:00:00.000Z',
  },
  13: {
    metric: 54,
    merged_at: '2019-08-06T22:00:00.000Z',
  },
  14: {
    metric: 64,
    merged_at: '2019-08-05T22:00:00.000Z',
  },
  15: {
    metric: 52,
    merged_at: '2019-08-04T22:00:00.000Z',
  },
  16: {
    metric: 56,
    merged_at: '2019-08-03T22:00:00.000Z',
  },
  17: {
    metric: 47,
    merged_at: '2019-08-02T22:00:00.000Z',
  },
  18: {
    metric: 49,
    merged_at: '2019-08-01T22:00:00.000Z',
  },
  19: {
    metric: 46,
    merged_at: '2019-07-31T22:00:00.000Z',
  },
  20: {
    metric: 57,
    merged_at: '2019-07-30T22:00:00.000Z',
  },
};

export const mockFilters = {
  authorUsername: 'root',
  milestoneTitle: ['13.0'],
  labelName: ['Label 1', 'Label 2'],
  notAuthorUsername: ['guest'],
  notMilestoneTitle: ['12.0'],
  notLabelName: ['Not Label 1', 'Not Label 2'],
};
