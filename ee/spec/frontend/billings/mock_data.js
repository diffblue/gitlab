export const mockDataSubscription = {
  gold: {
    plan: {
      name: 'Gold',
      code: 'gold',
      trial: false,
      upgradable: false,
      exclude_guests: true,
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
      exclude_guests: null,
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
      exclude_guests: false,
    },
    usage: {
      seats_in_subscription: 100,
      seats_in_use: 1,
      max_seats_used: 0,
      seats_owed: 0,
      exclude_guests: false,
    },
    billing: {
      subscription_start_date: '2018-12-13',
      subscription_end_date: '2019-12-13',
      trial_ends_on: '2019-12-13',
    },
  },
};

export const verificationModalDefaultGon = {
  current_user_id: 300,
  payment_validation_form_id: 'payment-validation-page-id',
};

export const verificationModalDefaultProps = {
  visible: false,
  iframeUrl: 'https://gitlab.com',
  allowedOrigin: 'https://gitlab.com',
};
