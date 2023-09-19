import { s__ } from '~/locale';

export const LIMITED_ACCESS_MESSAGING = Object.freeze({
  MANAGED_BY_RESELLER: {
    title: s__('SubscriptionMangement|Your subscription is in read-only mode'),
    content: s__(
      'SubscriptionMangement|To make changes to a read-only subscription or purchase additional products, contact your GitLab Partner.',
    ),
  },
  RAMP_SUBSCRIPTION: {
    title: s__(
      'SubscriptionMangement|This is a custom subscription managed by the GitLab Sales team',
    ),
    content: s__(
      "SubscriptionMangement|If you'd like to add more seats, upgrade your plan, or purchase additional products, contact your GitLab sales representative.",
    ),
  },
});
