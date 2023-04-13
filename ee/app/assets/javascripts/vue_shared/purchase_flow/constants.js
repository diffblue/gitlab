import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const GENERAL_ERROR_MESSAGE = s__(
  'PurchaseStep|An error occurred in the purchase step. If the problem persists please contact support at https://support.gitlab.com.',
);

export const licensingAndRenewalsProblemsLink =
  'https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293';
export const salesLink = 'https://about.gitlab.com/sales/';
export const userProfileLink = 'https://gitlab.com/-/profile';
export const linkCustomersPortalHelpLink = helpPagePath('subscriptions/customers_portal', {
  anchor: '#change-the-linked-account',
});
