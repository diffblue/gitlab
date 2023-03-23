import { GlFilteredSearchToken } from '@gitlab/ui';
import { groupMemberRequestFormatter } from '~/groups/members/utils';

import { __, n__, s__, sprintf } from '~/locale';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  AVAILABLE_FILTERED_SEARCH_TOKENS as AVAILABLE_FILTERED_SEARCH_TOKENS_CE,
  MEMBER_TYPES as MEMBER_TYPES_CE,
  TAB_QUERY_PARAM_VALUES as CE_TAB_QUERY_PARAM_VALUES,
} from '~/members/constants';
import { helpPagePath } from '~/helpers/help_page_helper';

// eslint-disable-next-line import/export
export * from '~/members/constants';

export const DISABLE_TWO_FACTOR_MODAL_ID = 'disable-two-factor-modal';

export const I18N_CANCEL = __('Cancel');
export const I18N_DISABLE = __('Disable');
export const I18N_DISABLE_TWO_FACTOR_MODAL_TITLE = s__('Members|Disable two-factor authentication');

export const LDAP_OVERRIDE_CONFIRMATION_MODAL_ID = 'ldap-override-confirmation-modal';

export const FILTERED_SEARCH_TOKEN_ENTERPRISE = {
  type: 'enterprise',
  icon: 'work',
  title: __('Enterprise'),
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATORS_IS,
  options: [
    { value: 'true', title: __('Yes') },
    { value: 'false', title: __('No') },
  ],
  requiredPermissions: 'canFilterByEnterprise',
};

export const FILTERED_SEARCH_USER_TYPE = {
  type: 'user_type',
  icon: 'account',
  title: __('Account'),
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATORS_IS,
  // Remove the single quotes surrounding `Service account` after this issue is closed: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2159
  options: [{ value: 'service_account', title: `'${__('Service account')}'` }],
  requiredPermissions: 'canManageMembers',
};

// eslint-disable-next-line import/export
export const AVAILABLE_FILTERED_SEARCH_TOKENS = [
  ...AVAILABLE_FILTERED_SEARCH_TOKENS_CE,
  FILTERED_SEARCH_TOKEN_ENTERPRISE,
  FILTERED_SEARCH_USER_TYPE,
];

// eslint-disable-next-line import/export
export const MEMBER_TYPES = {
  ...MEMBER_TYPES_CE,
  banned: 'banned',
};

// eslint-disable-next-line import/export
export const EE_ACTION_BUTTONS = {
  [MEMBER_TYPES.banned]: 'banned-action-buttons',
};

// eslint-disable-next-line import/export
export const TAB_QUERY_PARAM_VALUES = {
  ...CE_TAB_QUERY_PARAM_VALUES,
  banned: 'banned',
};

// eslint-disable-next-line import/export
export const EE_TABS = [
  {
    namespace: MEMBER_TYPES.banned,
    title: __('Banned'),
    queryParamValue: TAB_QUERY_PARAM_VALUES.banned,
  },
];

const uniqueProjectDownloadLimitEnabled =
  gon.features?.limitUniqueProjectDownloadsPerNamespaceUser &&
  gon.licensed_features?.uniqueProjectDownloadLimit;

// eslint-disable-next-line import/export
export const EE_APP_OPTIONS = uniqueProjectDownloadLimitEnabled
  ? {
      [MEMBER_TYPES.banned]: {
        tableFields: ['account', 'actions'],
        requestFormatter: groupMemberRequestFormatter,
      },
    }
  : {};

export const GUEST_OVERAGE_MODAL_FIELDS = Object.freeze({
  TITLE: __('You are about to incur additional charges'),
  LINK: helpPagePath('subscriptions/quarterly_reconciliation'),
  BACK_BUTTON_LABEL: __('Cancel'),
  CONTINUE_BUTTON_LABEL: __('Continue with overages'),
  LINK_TEXT: __('%{linkStart} Learn more%{linkEnd}.'),
});

export const overageModalInfoText = (quantity) =>
  n__(
    'MembersOverage|Your subscription includes %d seat.',
    'MembersOverage|Your subscription includes %d seats.',
    quantity,
  );

export const overageModalInfoWarning = (quantity, groupName) =>
  sprintf(
    n__(
      'MembersOverage|If you continue, the %{groupName} group will have %{quantity} seat in use and will be billed for the overage.',
      'MembersOverage|If you continue, the %{groupName} group will have %{quantity} seats in use and will be billed for the overage.',
      quantity,
    ),
    {
      groupName,
      quantity,
    },
  );

export const MEMBER_ACCESS_LEVELS = {
  GUEST: 10,
};
