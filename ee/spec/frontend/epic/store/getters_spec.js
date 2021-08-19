import { statusType } from 'ee/epic/constants';
import * as getters from 'ee/epic/store/getters';

describe('Epic Store Getters', () => {
  const dateString = '2018-01-01';
  const epicGetter = {
    startDateTime: 'startfoo',
    startDateTimeFromMilestones: 'startbar',
    dueDateTime: 'duefoo',
    dueDateTimeFromMilestones: 'duebar',
  };

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

  describe('startDateTime', () => {
    it('should return null when there is no startDate', () => {
      const epicState = {};

      expect(getters.startDateTime(epicState)).toEqual(null);
    });

    it('should return date', () => {
      const epicState = {
        startDate: dateString,
      };

      const date = getters.startDateTime(epicState);

      expect(date.getDate()).toEqual(1);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2018);
    });
  });

  describe('startDateTimeFixed', () => {
    it('should return null when there is no startDateFixed', () => {
      const epicState = {};

      expect(getters.startDateTimeFixed(epicState)).toEqual(null);
    });

    it('should return date', () => {
      const epicState = {
        startDateFixed: dateString,
      };

      const date = getters.startDateTimeFixed(epicState);

      expect(date.getDate()).toEqual(1);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2018);
    });
  });

  describe('startDateTimeFromMilestones', () => {
    it('should return null when there is no startDateFromMilestones', () => {
      const epicState = {};

      expect(getters.startDateTimeFromMilestones(epicState)).toEqual(null);
    });

    it('should return date', () => {
      const epicState = {
        startDateFromMilestones: dateString,
      };

      const date = getters.startDateTimeFromMilestones(epicState);

      expect(date.getDate()).toEqual(1);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2018);
    });
  });

  describe('dueDateTime', () => {
    it('should return null when there is no dueDate', () => {
      const epicState = {};

      expect(getters.dueDateTime(epicState)).toEqual(null);
    });

    it('should return date', () => {
      const epicState = {
        dueDate: dateString,
      };

      const date = getters.dueDateTime(epicState);

      expect(date.getDate()).toEqual(1);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2018);
    });
  });

  describe('dueDateTimeFixed', () => {
    it('should return null when there is no dueDateFixed', () => {
      const epicState = {};

      expect(getters.dueDateTimeFixed(epicState)).toEqual(null);
    });

    it('should return date', () => {
      const epicState = {
        dueDateFixed: dateString,
      };

      const date = getters.dueDateTimeFixed(epicState);

      expect(date.getDate()).toEqual(1);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2018);
    });
  });

  describe('dueDateTimeFromMilestones', () => {
    it('should return null when there is no dueDateFromMilestones', () => {
      const epicState = {};

      expect(getters.dueDateTimeFromMilestones(epicState)).toEqual(null);
    });

    it('should return date', () => {
      const epicState = {
        dueDateFromMilestones: dateString,
      };

      const date = getters.dueDateTimeFromMilestones(epicState);

      expect(date.getDate()).toEqual(1);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2018);
    });
  });

  describe('startDateForCollapsedSidebar', () => {
    it('should return startDateTime when startDateIsFixed is true', () => {
      const epicState = {
        startDateIsFixed: true,
      };

      expect(getters.startDateForCollapsedSidebar(epicState, epicGetter)).toEqual('startfoo');
    });

    it('should return startDateTimeFromMilestones when startDateIsFixed is false', () => {
      const epicState = {
        startDateIsFixed: false,
      };

      expect(getters.startDateForCollapsedSidebar(epicState, epicGetter)).toEqual('startbar');
    });
  });

  describe('dueDateForCollapsedSidebar', () => {
    it('should return dueDateTime when dueDateIsFixed is true', () => {
      const epicState = {
        dueDateIsFixed: true,
      };

      expect(getters.dueDateForCollapsedSidebar(epicState, epicGetter)).toEqual('duefoo');
    });

    it('should return dueDateTimeFromMilestones when dueDateIsFixed is false', () => {
      const epicState = {
        dueDateIsFixed: false,
      };

      expect(getters.dueDateForCollapsedSidebar(epicState, epicGetter)).toEqual('duebar');
    });
  });

  describe('isDateInvalid', () => {
    it('returns true when fixed start and due dates are invalid', () => {
      const epicState = {
        startDateIsFixed: true,
        dueDateIsFixed: true,
      };

      expect(
        getters.isDateInvalid(epicState, {
          startDateTime: new Date(2018, 0, 1),
          dueDateTime: new Date(2017, 0, 1),
        }),
      ).toBe(true);
    });

    it('returns false when fixed start and due dates are valid', () => {
      const epicState = {
        startDateIsFixed: true,
        dueDateIsFixed: true,
      };

      expect(
        getters.isDateInvalid(epicState, {
          startDateTime: new Date(2017, 0, 1),
          dueDateTime: new Date(2018, 0, 1),
        }),
      ).toBe(false);
    });

    it('returns true when milestone start and milestone due dates are invalid', () => {
      const epicState = {
        startDateIsFixed: false,
        dueDateIsFixed: false,
      };

      expect(
        getters.isDateInvalid(epicState, {
          startDateTimeFromMilestones: new Date(2018, 0, 1),
          dueDateTimeFromMilestones: new Date(2017, 0, 1),
        }),
      ).toBe(true);
    });

    it('returns false when milestone start and milestone due dates are valid', () => {
      const epicState = {
        startDateIsFixed: false,
        dueDateIsFixed: false,
      };

      expect(
        getters.isDateInvalid(epicState, {
          startDateTimeFromMilestones: new Date(2017, 0, 1),
          dueDateTimeFromMilestones: new Date(2018, 0, 1),
        }),
      ).toBe(false);
    });
  });
});
