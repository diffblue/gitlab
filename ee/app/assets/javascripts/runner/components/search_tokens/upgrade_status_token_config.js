import { s__ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import {
  UPGRADE_STATUS_AVAILABLE,
  UPGRADE_STATUS_RECOMMENDED,
  UPGRADE_STATUS_NOT_AVAILABLE,
  PARAM_KEY_UPGRADE_STATUS,
} from '../../constants';

const options = [
  { value: UPGRADE_STATUS_AVAILABLE, title: s__('Runners|Available') },
  { value: UPGRADE_STATUS_RECOMMENDED, title: s__('Runners|Recommended') },
  { value: UPGRADE_STATUS_NOT_AVAILABLE, title: s__('Runners|Up to date') },
];

export const upgradeStatusTokenConfig = {
  icon: 'upgrade',
  title: s__('Runners|Upgrade Status'),
  type: PARAM_KEY_UPGRADE_STATUS,
  token: BaseToken,
  unique: true,
  options: options.map(({ value, title }) => ({
    value,
    // Replace whitespace with a special character to avoid
    // splitting this value.
    // Replacing in each option, as translations may also
    // contain spaces!
    // see: https://gitlab.com/gitlab-org/gitlab/-/issues/344142
    // see: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1438
    title: title.replace(/\s/g, '\u00a0'),
  })),
  operators: OPERATOR_IS_ONLY,
};
