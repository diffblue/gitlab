import PasswordValidator from 'ee/password/password_validator';

describe('ee/password/password_validator', () => {
  it('when elements do not exist, it does not throw error', () => {
    expect(() => new PasswordValidator()).not.toThrow();
  });
});
