import { MIN_USERNAME_LENGTH } from '~/lib/utils/constants';
import {
  parseUsername,
  displayUsername,
  isValidUsername,
  isValidEntityId,
  createToken,
} from 'ee/audit_events/token_utils';

describe('Audit Event Text Utils', () => {
  describe('parseUsername', () => {
    it('returns the username without the @ character', () => {
      expect(parseUsername('@username')).toBe('username');
    });

    it('returns the username unchanged when it does not include a @ character', () => {
      expect(parseUsername('username')).toBe('username');
    });
  });

  describe('displayUsername', () => {
    it('returns the username with the @ character', () => {
      expect(displayUsername('username')).toBe('@username');
    });
  });

  describe('isValidUsername', () => {
    it('returns true if the username is valid', () => {
      const username = 'a'.repeat(MIN_USERNAME_LENGTH);
      expect(isValidUsername(username)).toBe(true);
    });

    it('returns false if the username is too short', () => {
      const username = 'a'.repeat(MIN_USERNAME_LENGTH - 1);
      expect(isValidUsername(username)).toBe(false);
    });

    it('returns false if the username is empty', () => {
      const username = '';
      expect(isValidUsername(username)).toBe(false);
    });
  });

  describe('isValidEntityId', () => {
    it('returns true if the entity id is a positive number', () => {
      const id = 1;
      expect(isValidEntityId(id)).toBe(true);
    });

    it('returns true if the entity id is a numeric string', () => {
      const id = '123';
      expect(isValidEntityId(id)).toBe(true);
    });

    it('returns false if the entity id is zero', () => {
      const id = 0;
      expect(isValidEntityId(id)).toBe(false);
    });

    it('returns false if the entity id is not numeric', () => {
      const id = 'abc';
      expect(isValidEntityId(id)).toBe(false);
    });
  });

  describe('createToken', () => {
    it('returns the expected token value', () => {
      const input = { type: 'member', data: 'abc' };

      expect(createToken(input)).toEqual({
        type: input.type,
        value: { data: input.data, operator: '=' },
      });
    });
  });
});
