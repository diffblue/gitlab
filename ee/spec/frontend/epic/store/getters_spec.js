import * as getters from 'ee/epic/store/getters';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';

describe('Epic Store Getters', () => {
  describe('isEpicOpen', () => {
    it('returns `true` when Epic `state` is `opened`', () => {
      const epicState = {
        state: STATUS_OPEN,
      };

      expect(getters.isEpicOpen(epicState)).toBe(true);
    });

    it('returns `false` when Epic `state` is `closed`', () => {
      const epicState = {
        state: STATUS_CLOSED,
      };

      expect(getters.isEpicOpen(epicState)).toBe(false);
    });
  });

  describe('isUserSignedIn', () => {
    it('return boolean representation of the value of `gon.current_user_id`', () => {
      gon.current_user_id = 0;

      expect(getters.isUserSignedIn()).toBe(false);

      gon.current_user_id = 1;

      expect(getters.isUserSignedIn()).toBe(true);
    });
  });
});
