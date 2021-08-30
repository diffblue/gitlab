import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';

const qrtlyReconciliationHelpPageUrl = helpPagePath('subscriptions/quarterly_reconciliation');

export const i18n = {
  title: s__('Admin|Quarterly reconciliation will occur on %{qrtlyDate}'),
  description: {
    ee: s__(`Admin|The number of max users in your instance exceeds the number of users in your license.
On %{qrtlyDate}, quarterly reconciliation occurs and you are automatically billed a prorated amount
for the overage. No action is needed from you. If you have a credit card on file, it will be charged.
Otherwise, you will receive an invoice. For more information about the timing of the invoicing process, view the documentation.`),
    usesNamespacePlan: s__(`Admin|The number of max seats in your namespace exceeds the number of seats in your subscription.
On %{qrtlyDate}, quarterly reconciliation occurs and you are automatically billed a prorated amount
for the overage. No action is needed from you. If you have a credit card on file, it will be charged.
Otherwise, you will receive an invoice. For more information about the timing of the invoicing process, view the documentation.`),
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
