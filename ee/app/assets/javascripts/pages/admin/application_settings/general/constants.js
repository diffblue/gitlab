import { s__ } from '~/locale';

export const I18N = {
  passwordNumberRequiredLabel: s__('ApplicationSettings|Require numbers'),
  passwordNumberRequiredHelpText: s__(
    'ApplicationSettings|When enabled, new passwords must contain at least one number (0-9).',
  ),
  passwordUppercaseRequiredLabel: s__('ApplicationSettings|Require uppercase letters'),
  passwordUppercaseRequiredHelpText: s__(
    'ApplicationSettings|When enabled, new passwords must contain at least one uppercase letter (A-Z).',
  ),
  passwordLowercaseRequiredLabel: s__('ApplicationSettings|Require lowercase letters'),
  passwordLowercaseRequiredHelpText: s__(
    'ApplicationSettings|When enabled, new passwords must contain at least one lowercase letter (a-z).',
  ),
  passwordSymbolRequiredLabel: s__('ApplicationSettings|Require symbols'),
  passwordSymbolRequiredHelpText: s__(
    'ApplicationSettings|When enabled, new passwords must contain at least one symbol.',
  ),
};
