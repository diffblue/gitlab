import { AJAX_USERS_SELECT_PARAMS_MAP as CE_AJAX_USERS_SELECT_PARAMS_MAP } from '~/users_select/constants';

export const AJAX_USERS_SELECT_PARAMS_MAP = {
  ...CE_AJAX_USERS_SELECT_PARAMS_MAP,
  saml_provider_id: 'samlProviderId',
};
