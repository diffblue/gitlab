import { s__ } from '~/locale';

export const NUMBER = 'number';
export const UPPERCASE = 'uppercase';
export const LOWERCASE = 'lowercase';
export const SYMBOL = 'symbol';
export const INVALID_FORM_CLASS = 'show-password-complexity-errors';
export const INVALID_INPUT_CLASS = 'password-complexity-error-outline';
export const PASSWORD_REQUIREMENTS_ID = 'password-requirements';
export const RED_TEXT_CLASS = 'gl-text-red-500';
export const GREEN_TEXT_CLASS = 'gl-text-green-500';
export const HIDDEN_ELEMENT_CLASS = 'gl-visibility-hidden';

export const I18N = {
  PASSWORD_SATISFIED: s__('Password|Satisfied'),
  PASSWORD_NOT_SATISFIED: s__('Password|Not satisfied'),
  PASSWORD_TO_BE_SATISFIED: s__('Password|To be satisfied'),
};
export const PASSWORD_RULE_MAP = {
  [NUMBER]: {
    reg: /\p{N}/u,
    text: s__('Password|requires at least one number'),
  },

  [LOWERCASE]: {
    reg: /\p{Lower}/u,
    text: s__('Password|requires at least one lowercase letter'),
  },

  [UPPERCASE]: {
    reg: /\p{Upper}/u,
    text: s__('Password|requires at least one uppercase letter'),
  },
  [SYMBOL]: {
    reg: /[^\p{N}\p{Upper}\p{Lower}]/u,
    text: s__('Password|requires at least one symbol character'),
  },
};
