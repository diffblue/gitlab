import { s__ } from '~/locale';

export default () => ({
  isLoadingSubscription: false,
  hasErrorSubscription: false,
  namespaceId: null,
  plan: {
    code: null,
    name: null,
    trial: false,
    upgradable: false,
  },
  billing: {
    subscriptionStartDate: null,
    subscriptionEndDate: null,
  },
  tables: {
    free: {
      rows: [
        {
          header: {
            icon: 'monitor',
            title: s__('SubscriptionTable|Usage'),
          },
          columns: [
            {
              id: 'seatsInUse',
              label: s__('SubscriptionTable|Seats currently in use'),
              value: null,
              colClass: 'number',
              popover: {
                content: s__(
                  'SubscriptionTable|This is the number of seats you will be required to purchase if you update to a paid plan.',
                ),
              },
            },
            {
              id: 'subscriptionStartDate',
              label: s__('SubscriptionTable|Subscription start date'),
              value: null,
              isDate: true,
            },
          ],
        },
      ],
    },
    trial: {
      rows: [
        {
          header: {
            icon: 'monitor',
            title: s__('SubscriptionTable|Usage'),
          },
          columns: [
            {
              id: 'seatsInUse',
              label: s__('SubscriptionTable|Seats currently in use'),
              value: null,
              colClass: 'number',
              popover: {
                content: s__(
                  'SubscriptionTable|This is the number of seats you will be required to purchase if you update to a paid plan.',
                ),
              },
            },
            {
              id: 'subscriptionStartDate',
              label: s__('SubscriptionTable|Trial start date'),
              value: null,
              isDate: true,
            },
            {
              id: 'trialEndsOn',
              label: s__('SubscriptionTable|Trial end date'),
              value: null,
              isDate: true,
            },
          ],
        },
      ],
    },
    default: {
      rows: [
        {
          header: {
            icon: 'monitor',
            title: s__('SubscriptionTable|Usage'),
          },
          columns: [
            {
              id: 'seatsInSubscription',
              label: s__('SubscriptionTable|Seats in subscription'),
              value: null,
              colClass: 'number',
            },
            {
              id: 'seatsInUse',
              label: s__('SubscriptionTable|Seats currently in use'),
              value: null,
              colClass: 'number',
              popover: {
                content: s__('SubscriptionTable|Usage count is performed once a day at 12:00 PM.'),
              },
            },
            {
              id: 'maxSeatsUsed',
              label: s__('SubscriptionTable|Max seats used'),
              value: null,
              colClass: 'number',
              popover: {
                content: s__(
                  'SubscriptionTable|This is the maximum number of users that have existed at the same time since this subscription started.',
                ),
              },
            },
            {
              id: 'seatsOwed',
              label: s__('SubscriptionTable|Seats owed'),
              value: null,
              colClass: 'number',
              popover: {
                content: s__(
                  'SubscriptionTable|GitLab allows you to continue using your subscription even if you exceed the number of seats you purchased. You will be required to pay for these seats upon renewal.',
                ),
              },
            },
          ],
        },
        {
          header: {
            icon: 'calendar',
            title: s__('SubscriptionTable|Billing'),
          },
          columns: [
            {
              id: 'subscriptionStartDate',
              label: s__('SubscriptionTable|Subscription start date'),
              value: null,
              isDate: true,
            },
            {
              id: 'subscriptionEndDate',
              label: s__('SubscriptionTable|Subscription end date'),
              value: null,
              isDate: true,
            },
            {
              id: 'lastInvoice',
              label: s__('SubscriptionTable|Last invoice'),
              value: null,
              isDate: true,
              popover: {
                content: s__(
                  'SubscriptionTable|This is the last time the GitLab.com team was in contact with you to settle any outstanding balances.',
                ),
              },
              hideContent: true, // temporarily display a blank cell (as we don't have content yet)
            },
            {
              id: 'nextInvoice',
              label: s__('SubscriptionTable|Next invoice'),
              value: null,
              isDate: true,
              popover: {
                content: s__(
                  'SubscriptionTable|This is the next date when the GitLab.com team is scheduled to get in contact with you to settle any outstanding balances.',
                ),
              },
              hideContent: true, // temporarily display a blank cell (as we don't have content yet)
            },
          ],
        },
      ],
    },
  },
});
