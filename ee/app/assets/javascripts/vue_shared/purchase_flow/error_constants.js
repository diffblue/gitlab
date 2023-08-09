import { s__ } from '~/locale';
import {
  GENERAL_ERROR_MESSAGE,
  linkCustomersPortalHelpLink,
  licensingAndRenewalsProblemsLink,
  salesLink,
  userProfileLink,
} from 'ee/vue_shared/purchase_flow/constants';
import { convertObjectPropsToLowerCase } from '~/lib/utils/common_utils';

export const CONTACT_SUPPORT_DEFAULT_MESSAGE = {
  message: GENERAL_ERROR_MESSAGE,
  links: {},
};

export const DECLINED_CARD_GENERIC_ERROR = {
  message: s__(
    'Purchase|Your card was declined. Contact your card issuer for more information or %{salesLinkStart}contact our sales team%{salesLinkEnd} to pay with an alternative payment method.',
  ),
  links: {
    salesLink,
  },
};

export const DECLINED_CARD_FUNDS_ERROR = {
  message: s__(
    'Purchase|Your card was declined due to insufficient funds. Make sure you have sufficient funds, then retry the purchase or use a different card. If the problem persists, %{supportLinkStart}contact support%{supportLinkEnd}.',
  ),
  links: {
    supportLink: licensingAndRenewalsProblemsLink,
  },
};

export const EXPIRED_SUBSCRIPTION_ERROR = {
  message: s__(
    'Purchase|An error occurred with your purchase because your group is currently linked to an expired subscription. %{supportLinkStart}Open a support ticket%{supportLinkEnd}, and our support team will assist with a workaround.',
  ),
  links: {
    supportLink: licensingAndRenewalsProblemsLink,
  },
};

export const FULL_NAME_REQUIRED_ERROR = {
  message: s__(
    'Purchase|A full name in your profile is required to make a purchase. Check that the full name field in your %{userProfileLinkStart}user profile%{userProfileLinkEnd} has both a first and last name, then retry the purchase. If the problem persists, %{supportLinkStart}contact support%{supportLinkEnd}.',
  ),
  links: {
    supportLink: licensingAndRenewalsProblemsLink,
    userProfileLink,
  },
};

export const UNLINKED_ACCOUNT_ERROR = {
  message: s__(
    'Purchase|An error occurred with your purchase. We detected a %{customersPortalLinkStart}Customers Portal%{customersPortalLinkEnd} account that matches your email address, but it has not been linked to your GitLab.com account. Follow the %{linkCustomersPortalHelpLinkStart}instructions to link your Customers Portal account%{linkCustomersPortalHelpLinkEnd}, and retry the purchase. If the problem persists, %{supportLinkStart}contact support%{supportLinkEnd}.',
  ),
  links: {
    linkCustomersPortalHelpLink,
    customersPortalLink: gon.subscriptions_legacy_sign_in_url,
    supportLink: licensingAndRenewalsProblemsLink,
  },
};

/* eslint-disable @gitlab/require-i18n-strings */
const cannotBeBlank = "can't be blank";
const alreadyTaken = 'has already been taken';

export const CONTRACT_EFFECTIVE_ERROR =
  'The Contract effective date should not be later than the term end date of the basic subscription';
export const GENERIC_DECLINE_ERROR =
  'Transaction declined.generic_decline - Your card was declined';
export const EMAIL_TAKEN_ERROR = `Email ${alreadyTaken}`;
export const EMAIL_TAKEN_ERROR_TYPE = 'email:taken';
export const INSUFFICIENT_FUNDS_ERROR = 'Your card has insufficient funds.';
export const FIRST_NAME_BLANK_ERROR = `First name ${cannotBeBlank}`;
export const LAST_NAME_BLANK_ERROR = `Last name ${cannotBeBlank}`;

// The following messages can be removed after this MR has landed:
// https://gitlab.com/gitlab-org/customers-gitlab-com/-/merge_requests/6970
export const FIRST_NAME_BLANK_ERROR_VARIATION = JSON.stringify({ first_name: [cannotBeBlank] });
export const LAST_NAME_BLANK_ERROR_VARIATION_1 = JSON.stringify({ last_name: [cannotBeBlank] });
export const LAST_NAME_BLANK_ERROR_VARIATION_2 = `{${LAST_NAME_BLANK_ERROR}}`;
/* eslint-enable @gitlab/require-i18n-strings */

export const PURCHASE_ERROR_DICTIONARY = convertObjectPropsToLowerCase({
  [CONTRACT_EFFECTIVE_ERROR]: EXPIRED_SUBSCRIPTION_ERROR,
  [GENERIC_DECLINE_ERROR]: DECLINED_CARD_GENERIC_ERROR,
  [EMAIL_TAKEN_ERROR]: UNLINKED_ACCOUNT_ERROR,
  [EMAIL_TAKEN_ERROR_TYPE]: UNLINKED_ACCOUNT_ERROR,
  [INSUFFICIENT_FUNDS_ERROR]: DECLINED_CARD_FUNDS_ERROR,
  [FIRST_NAME_BLANK_ERROR]: FULL_NAME_REQUIRED_ERROR,
  [FIRST_NAME_BLANK_ERROR_VARIATION]: FULL_NAME_REQUIRED_ERROR,
  [LAST_NAME_BLANK_ERROR]: FULL_NAME_REQUIRED_ERROR,
  [LAST_NAME_BLANK_ERROR_VARIATION_1]: FULL_NAME_REQUIRED_ERROR,
  [LAST_NAME_BLANK_ERROR_VARIATION_2]: FULL_NAME_REQUIRED_ERROR,
});
