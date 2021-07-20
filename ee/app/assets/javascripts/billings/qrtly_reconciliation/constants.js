import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';

const qrtlyReconciliationHelpPageUrl = helpPagePath('subscriptions/quarterly_reconciliation');

export const i18n = {
  title: s__('Admin|Quarterly reconciliation will occur on %{qrtlyDate}'),
  description: {
    ee: s__(`Admin|The number of maximum users for your instance
is currently exceeding the number of users in license.
On %{qrtlyDate}, GitLab will process a quarterly reconciliation
and automatically bill you a prorated amount for the overage.
There is no action needed from you. If you have a credit card on file,
it will be charged. Otherwise, you will receive an invoice.`),
    usesNamespacePlan: s__(`Admin|The number of max seats used for your namespace is currently
exceeding the number of seats in your subscription.
On %{qrtlyDate}, GitLab will process a quarterly reconciliation and
automatically bill you a prorated amount for the overage.
There is no action needed from you. If you have a credit card on file, it will be charged.
Otherwise, you will receive an invoice.`),
  },
  buttons: {
    primary: {
      text: s__('Admin|Learn more about quarterly reconciliation'),
      link: qrtlyReconciliationHelpPageUrl,
    },
    secondary: {
      text: __('Contact support'),
      link: 'https://about.gitlab.com/support/#contact-support',
    },
  },
};
