import { s__ } from '~/locale';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { convertObjectPropsToLowerCase } from '~/lib/utils/common_utils';

const salesLink = `${PROMO_URL}/sales/`;
const supportLink = `${PROMO_URL}/support/`;

const NO_SEATS_AVAILABLE_ERROR = {
  title: s__('Billing|No seats available'),
  message: s__(
    'Billing|You have assigned all available Code Suggestions add-on seats. Please %{salesLinkStart}contact sales%{salesLinkEnd} if you would like to purchase more seats.',
  ),
  links: { salesLink },
};

const GENERAL_ADD_ON_ASSIGNMENT_ERROR = {
  title: s__('Billing|Error assigning Code Suggestions add-on'),
  message: s__(
    'Billing|Something went wrong when assigning the add-on to this member. If the problem persists, please %{supportLinkStart}contact support%{supportLinkEnd}.',
  ),
  links: { supportLink },
};

const GENERAL_ADD_ON_UNASSIGNMENT_ERROR = {
  title: s__('Billing|Error un-assigning Code Suggestions add-on'),
  message: s__(
    'Billing|Something went wrong when un-assigning the add-on to this member. If the problem persists, please %{supportLinkStart}contact support%{supportLinkEnd}.',
  ),
  links: { supportLink },
};

export const ADDON_PURCHASE_FETCH_ERROR = {
  message: s__(
    'Billing|An error occurred while loading details for the Code Suggestions add-on. If the problem persists, please %{supportLinkStart}contact support%{supportLinkEnd}.',
  ),
  links: { supportLink },
};

const NO_SEATS_AVAILABLE_ERROR_CODE = 'NO_SEATS_AVAILABLE';
export const CANNOT_ASSIGN_ADDON_ERROR_CODE = 'CANNOT_ASSIGN_ADDON';
export const CANNOT_UNASSIGN_ADDON_ERROR_CODE = 'CANNOT_UNASSIGN_ADDON';
export const ADD_ON_PURCHASE_FETCH_ERROR_CODE = 'ADD_ON_PURCHASE_FETCH_ERROR';

export const ADD_ON_ERROR_DICTIONARY = convertObjectPropsToLowerCase({
  [NO_SEATS_AVAILABLE_ERROR_CODE]: NO_SEATS_AVAILABLE_ERROR,
  [CANNOT_ASSIGN_ADDON_ERROR_CODE]: GENERAL_ADD_ON_ASSIGNMENT_ERROR,
  [CANNOT_UNASSIGN_ADDON_ERROR_CODE]: GENERAL_ADD_ON_UNASSIGNMENT_ERROR,
  [ADD_ON_PURCHASE_FETCH_ERROR_CODE]: ADDON_PURCHASE_FETCH_ERROR,
});
