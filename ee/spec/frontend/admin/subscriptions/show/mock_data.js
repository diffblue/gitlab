import { CONNECTIVITY_ERROR, subscriptionTypes } from 'ee/admin/subscriptions/show/constants';

export const license = {
  ULTIMATE: {
    activatedAt: '2022-03-16',
    billableUsersCount: '8',
    expiresAt: '2022-03-16',
    company: 'ACME Corp',
    email: 'user@acmecorp.com',
    id: 'gid://gitlab/License/13',
    lastSync: '2021-03-16T00:00:00.000',
    maximumUserCount: '8',
    name: 'Jane Doe',
    plan: 'ultimate',
    startsAt: '2021-03-11',
    type: subscriptionTypes.ONLINE_CLOUD,
    usersInLicenseCount: '10',
    usersOverLicenseCount: '0',
  },
  ULTIMATE_FUTURE_DATED: {
    activatedAt: '2021-03-16',
    billableUsersCount: '8',
    expiresAt: '2023-03-16',
    company: 'ACME Corp',
    email: 'user@acmecorp.com',
    id: 'gid://gitlab/License/13',
    lastSync: '2021-03-16T00:00:00.000',
    maximumUserCount: '8',
    name: 'Jane Doe',
    plan: 'ultimate',
    startsAt: '2022-03-16',
    type: subscriptionTypes.ONLINE_CLOUD,
    usersInLicenseCount: '10',
    usersOverLicenseCount: '0',
  },
};

export const subscriptionPastHistory = [
  {
    activatedAt: '2022-03-16',
    company: 'ACME Corp',
    email: 'user@acmecorp.com',
    expiresAt: '2022-03-16',
    id: 'gid://gitlab/License/13',
    name: 'Jane Doe',
    plan: 'ultimate',
    startsAt: '2021-03-11',
    type: subscriptionTypes.ONLINE_CLOUD,
    usersInLicenseCount: '10',
  },
  {
    activatedAt: '2020-11-05',
    company: 'ACME Corp',
    email: 'user@acmecorp.com',
    expiresAt: '2021-03-16',
    id: 'gid://gitlab/License/11',
    name: 'Jane Doe',
    plan: 'premium',
    startsAt: '2020-03-16',
    type: subscriptionTypes.LEGACY_LICENSE,
    usersInLicenseCount: '5',
  },
];

export const subscriptionFutureHistory = [
  {
    company: 'ACME Corp',
    email: 'user@acmecorp.com',
    expiresAt: '2023-03-16',
    name: 'Jane Doe',
    plan: 'ultimate',
    startsAt: '2022-03-11',
    type: subscriptionTypes.OFFLINE_CLOUD,
    usersInLicenseCount: '15',
  },
  {
    company: 'ACME Corp',
    email: 'user@acmecorp.com',
    expiresAt: '2022-03-16',
    name: 'Jane Doe',
    plan: 'ultimate',
    startsAt: '2021-03-16',
    type: subscriptionTypes.ONLINE_CLOUD,
    usersInLicenseCount: '10',
  },
];

export function makeSubscriptionFutureEntry(subscription) {
  return { __typename: 'SubscriptionFutureEntry', ...subscription };
}

export const activateLicenseMutationResponse = {
  FAILURE: [
    {
      errors: [
        {
          message:
            'Variable $gitlabSubscriptionActivateInput of type GitlabSubscriptionActivateInput! was provided invalid value',
          locations: [
            {
              line: 1,
              column: 11,
            },
          ],
          extensions: {
            value: null,
            problems: [
              {
                path: [],
                explanation: 'Expected value to not be null',
              },
            ],
          },
        },
      ],
    },
  ],
  CONNECTIVITY_ERROR: {
    data: {
      gitlabSubscriptionActivate: {
        license: null,
        futureSubscriptions: [],
        errors: [CONNECTIVITY_ERROR],
        __typename: 'GitlabSubscriptionActivatePayload',
      },
    },
  },
  INVALID_CODE_ERROR: {
    data: {
      gitlabSubscriptionActivate: {
        license: null,
        futureSubscriptions: [],
        errors: ['invalid activation code'],
        __typename: 'GitlabSubscriptionActivatePayload',
      },
    },
  },
  ERRORS_AS_DATA: {
    data: {
      gitlabSubscriptionActivate: {
        license: null,
        futureSubscriptions: [],
        errors: ["undefined method `[]' for nil:NilClass"],
        __typename: 'GitlabSubscriptionActivatePayload',
      },
    },
  },
  SUCCESS: {
    data: {
      gitlabSubscriptionActivate: {
        license: {
          __typename: 'CurrentLicense',
          id: 'gid://gitlab/License/3',
          type: 'online_cloud',
          plan: 'ultimate',
          name: 'Online license',
          email: 'user@example.com',
          company: 'Example Inc',
          startsAt: '2020-01-01',
          expiresAt: '2022-01-01',
          activatedAt: '2021-01-02',
          lastSync: null,
          usersInLicenseCount: 100,
          billableUsersCount: 50,
          maximumUserCount: 50,
          usersOverLicenseCount: 0,
        },
        futureSubscriptions: [],
        errors: [],
      },
    },
  },
};

export const fakeActivationCodeTrimmed = 'aaaassssddddffff992200gg';
export const fakeActivationCode = `    ${fakeActivationCodeTrimmed}   `;
