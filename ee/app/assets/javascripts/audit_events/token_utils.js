// These methods need to be separate from `./utils.js` to avoid a circular dependency.

import { MIN_USERNAME_LENGTH } from '~/lib/utils/constants';
import { isNumeric } from '~/lib/utils/number_utils';

export const parseUsername = (username) =>
  username && String(username).startsWith('@') ? username.slice(1) : username;

export const displayUsername = (username) => (username ? `@${username}` : null);

export const isValidUsername = (username) =>
  Boolean(username) && username.length >= MIN_USERNAME_LENGTH;

export const isValidEntityId = (id) => Boolean(id) && isNumeric(id) && parseInt(id, 10) > 0;

export const createToken = ({ type, data }) => ({
  type,
  value: { data, operator: '=' },
});
