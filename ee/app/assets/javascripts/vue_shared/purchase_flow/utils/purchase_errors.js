import { isEmpty, isString } from 'lodash';
import { sprintf, s__ } from '~/locale';
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
    customersPortalLink: gon.subscriptions_url,
    supportLink: licensingAndRenewalsProblemsLink,
  },
};

export const CONTRACT_EFFECTIVE_ERROR =
  'The Contract effective date should not be later than the term end date of the basic subscription';
export const EMAIL_TAKEN_ERROR = '{"email"=>["has already been taken"]}';
export const GENERIC_DECLINE_ERROR =
  'Transaction declined.generic_decline - Your card was declined';
export const INSUFFICIENT_FUNDS_ERROR = 'Your card has insufficient funds.';
export const LAST_NAME_BLANK_ERROR = '"last_name":["can\'t be blank"]';

export const errorDictionary = convertObjectPropsToLowerCase({
  [CONTRACT_EFFECTIVE_ERROR]: EXPIRED_SUBSCRIPTION_ERROR,
  [GENERIC_DECLINE_ERROR]: DECLINED_CARD_GENERIC_ERROR,
  [EMAIL_TAKEN_ERROR]: UNLINKED_ACCOUNT_ERROR,
  [INSUFFICIENT_FUNDS_ERROR]: DECLINED_CARD_FUNDS_ERROR,
  [LAST_NAME_BLANK_ERROR]: FULL_NAME_REQUIRED_ERROR,
});

export const mapSystemToFriendlyError = (systemError) => {
  if (systemError && isString(systemError)) {
    return (
      errorDictionary[systemError.toLowerCase()] || {
        message: systemError,
        links: {},
      }
    );
  }

  return CONTACT_SUPPORT_DEFAULT_MESSAGE;
};

const generateLinks = (links) => {
  return Object.keys(links).reduce((allLinks, link) => {
    /* eslint-disable-next-line @gitlab/require-i18n-strings */
    const linkStart = `${link}Start`;
    /* eslint-disable-next-line @gitlab/require-i18n-strings */
    const linkEnd = `${link}End`;

    return {
      ...allLinks,
      [linkStart]: `<a href="${links[link]}" target="_blank" rel=“noopener noreferrer”>`,
      [linkEnd]: '</a>',
    };
  }, {});
};

export const generateHelpTextWithLinks = (error) => {
  if (isString(error)) {
    return error;
  }

  if (isEmpty(error)) {
    /* eslint-disable-next-line @gitlab/require-i18n-strings */
    throw new Error('The error cannot be empty.');
  }

  const links = generateLinks(error.links);
  return sprintf(error.message, links, false);
};
