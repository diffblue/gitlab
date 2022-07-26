import { GlFilteredSearchToken } from '@gitlab/ui';
import { groupMemberRequestFormatter } from '~/groups/members/utils';

import { __ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  AVAILABLE_FILTERED_SEARCH_TOKENS as AVAILABLE_FILTERED_SEARCH_TOKENS_CE,
  MEMBER_TYPES as MEMBER_TYPES_CE,
  TAB_QUERY_PARAM_VALUES as CE_TAB_QUERY_PARAM_VALUES,
} from '~/members/constants';

// eslint-disable-next-line import/export
export * from '~/members/constants';

export const LDAP_OVERRIDE_CONFIRMATION_MODAL_ID = 'ldap-override-confirmation-modal';

export const FILTERED_SEARCH_TOKEN_ENTERPRISE = {
  type: 'enterprise',
  icon: 'work',
  title: __('Enterprise'),
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATOR_IS_ONLY,
  options: [
    { value: 'true', title: __('Yes') },
    { value: 'false', title: __('No') },
  ],
  requiredPermissions: 'canFilterByEnterprise',
};

// eslint-disable-next-line import/export
export const AVAILABLE_FILTERED_SEARCH_TOKENS = [
  ...AVAILABLE_FILTERED_SEARCH_TOKENS_CE,
  FILTERED_SEARCH_TOKEN_ENTERPRISE,
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
    canManageMembersPermissionsRequired: true,
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
