import { GlFilteredSearchToken } from '@gitlab/ui';

import { __ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import { AVAILABLE_FILTERED_SEARCH_TOKENS as AVAILABLE_FILTERED_SEARCH_TOKENS_CE } from '~/members/constants';

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
    { value: true, title: __('Yes') },
    { value: false, title: __('No') },
  ],
  requiredPermissions: 'canFilterByEnterprise',
};

// eslint-disable-next-line import/export
export const AVAILABLE_FILTERED_SEARCH_TOKENS = [
  ...AVAILABLE_FILTERED_SEARCH_TOKENS_CE,
  FILTERED_SEARCH_TOKEN_ENTERPRISE,
];
