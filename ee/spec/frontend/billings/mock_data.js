import {
  HEADER_TOTAL_ENTRIES,
  HEADER_PAGE_NUMBER,
  HEADER_ITEMS_PER_PAGE,
} from 'ee/billings/constants';

export const mockDataSubscription = {
  gold: {
    plan: {
      name: 'Gold',
      code: 'gold',
      trial: false,
      upgradable: false,
    },
    usage: {
      seats_in_subscription: 100,
      seats_in_use: 98,
      max_seats_used: 104,
      seats_owed: 4,
    },
    billing: {
      subscription_start_date: '2018-07-11',
      subscription_end_date: '2019-07-11',
      last_invoice: '2018-09-01',
      next_invoice: '2018-10-01',
    },
  },
  free: {
    plan: {
      name: null,
      code: null,
      trial: null,
      upgradable: null,
    },
    usage: {
      seats_in_subscription: 0,
      seats_in_use: 0,
      max_seats_used: 5,
      seats_owed: 0,
    },
    billing: {
      subscription_start_date: '2018-10-30',
      subscription_end_date: null,
      trial_ends_on: null,
    },
  },
  trial: {
    plan: {
      name: 'Gold',
      code: 'gold',
      trial: true,
      upgradable: false,
    },
    usage: {
      seats_in_subscription: 100,
      seats_in_use: 1,
      max_seats_used: 0,
      seats_owed: 0,
    },
    billing: {
      subscription_start_date: '2018-12-13',
      subscription_end_date: '2019-12-13',
      trial_ends_on: '2019-12-13',
    },
  },
};

export const mockDataSeats = {
  data: [
    {
      id: 2,
      name: 'Administrator',
      username: 'root',
      avatar_url: 'path/to/img_administrator',
      web_url: 'path/to/administrator',
      email: 'administrator@email.com',
      last_activity_on: '2020-03-01',
      membership_type: 'group_member',
      removable: true,
    },
    {
      id: 3,
      name: 'Agustin Walker',
      username: 'lester.orn',
      avatar_url: 'path/to/img_agustin_walker',
      web_url: 'path/to/agustin_walker',
      email: 'agustin_walker@email.com',
      last_activity_on: '2020-03-01',
      membership_type: 'group_member',
      removable: true,
    },
    {
      id: 4,
      name: 'Joella Miller',
      username: 'era',
      avatar_url: 'path/to/img_joella_miller',
      web_url: 'path/to/joella_miller',
      last_activity_on: null,
      email: null,
      membership_type: 'group_invite',
      removable: false,
    },
    {
      id: 5,
      name: 'John Doe',
      username: 'jdoe',
      avatar_url: 'path/to/img_john_doe',
      web_url: 'path/to/john_doe',
      last_activity_on: null,
      email: 'jdoe@email.com',
      membership_type: 'project_invite',
      removable: false,
    },
  ],
  headers: {
    [HEADER_TOTAL_ENTRIES]: '3',
    [HEADER_PAGE_NUMBER]: '1',
    [HEADER_ITEMS_PER_PAGE]: '1',
  },
};

export const mockMemberDetails = [
  {
    id: 173,
    source_id: 155,
    source_full_name: 'group_with_ultimate_plan / subgroup',
    created_at: '2021-02-25T08:21:32.257Z',
    expires_at: null,
    access_level: { string_value: 'Owner', integer_value: 50 },
  },
];

export const mockTableItems = [
  {
    email: 'administrator@email.com',
    user: {
      id: 2,
      avatar_url: 'path/to/img_administrator',
      name: 'Administrator',
      username: '@root',
      web_url: 'path/to/administrator',
      last_activity_on: '2020-03-01',
      membership_type: 'group_member',
      removable: true,
    },
  },
  {
    email: 'agustin_walker@email.com',
    user: {
      id: 3,
      avatar_url: 'path/to/img_agustin_walker',
      name: 'Agustin Walker',
      username: '@lester.orn',
      web_url: 'path/to/agustin_walker',
      last_activity_on: '2020-03-01',
      membership_type: 'group_member',
      removable: true,
    },
  },
  {
    email: null,
    user: {
      id: 4,
      avatar_url: 'path/to/img_joella_miller',
      name: 'Joella Miller',
      username: '@era',
      web_url: 'path/to/joella_miller',
      last_activity_on: null,
      membership_type: 'group_invite',
      removable: false,
    },
  },
  {
    email: 'jdoe@email.com',
    user: {
      id: 5,
      avatar_url: 'path/to/img_john_doe',
      name: 'John Doe',
      username: '@jdoe',
      web_url: 'path/to/john_doe',
      last_activity_on: null,
      membership_type: 'project_invite',
      removable: false,
    },
  },
];
