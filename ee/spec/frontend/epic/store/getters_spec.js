import { statusType } from 'ee/epic/constants';
import * as getters from 'ee/epic/store/getters';

describe('Epic Store Getters', () => {
  describe('isEpicOpen', () => {
    it('returns `true` when Epic `state` is `opened`', () => {
      const epicState = {
        state: statusType.open,
      };

      expect(getters.isEpicOpen(epicState)).toBe(true);
    });

    it('returns `false` when Epic `state` is `closed`', () => {
      const epicState = {
        state: statusType.closed,
      };

      expect(getters.isEpicOpen(epicState)).toBe(false);
    });
  });

  describe('isUserSignedIn', () => {
    const originalUserId = gon.current_user_id;

    afterAll(() => {
      gon.current_user_id = originalUserId;
    });

    it('return boolean representation of the value of `gon.current_user_id`', () => {
      gon.current_user_id = 0;

      expect(getters.isUserSignedIn()).toBe(false);

      gon.current_user_id = 1;

      expect(getters.isUserSignedIn()).toBe(true);
    });
  });
});
