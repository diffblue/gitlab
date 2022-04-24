import { s__ } from '~/locale';

export const NUMBER = 'number';
export const UPPERCASE = 'uppercase';
export const LOWERCASE = 'lowercase';
export const SYMBOL = 'symbol';
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
