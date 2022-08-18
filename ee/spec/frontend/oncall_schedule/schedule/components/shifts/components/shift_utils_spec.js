import {
  getTotalTime,
  getTimeOffset,
  getDuration,
  getPixelOffset,
  getShiftContainerStyles,
  milliseconds,
} from 'ee/oncall_schedules/components/schedule/components/shifts/components/shift_utils';
import { PRESET_TYPES } from 'ee/oncall_schedules/constants';

// An 8 hour shift
const mockShift = {
  startsAt: '2021-01-13T12:00:00.000Z',
  endsAt: '2021-01-13T20:00:00.000Z',
  participant: null,
};

const ONE_HOUR = 60 * 60 * 1000;
const EIGHT_HOURS = 8 * ONE_HOUR;
const TWELVE_HOURS = 12 * ONE_HOUR;
const ONE_DAY = 2 * TWELVE_HOURS;
const TWO_WEEKS = 14 * ONE_DAY;

const timeframe = [new Date('2021-01-13T00:00:00.000Z'), new Date('2021-01-14T00:00:00.000Z')];

describe('~ee/oncall_schedules/components/schedule/components/shifts/components/shift_utils.js', () => {
  describe('milliseconds', () => {
    const mockDSLOffset = { m: 300 };

    it('returns a millisecond representation of a passed object', () => {
      expect(milliseconds(mockDSLOffset)).toBe(18000000);
    });
  });

  describe('getTotalTime', () => {
    it('returns the correct length for the days view', () => {
      expect(getTotalTime(PRESET_TYPES.DAYS)).toBe(ONE_DAY);
    });

    it('returns the correct length for the 2 week view', () => {
      expect(getTotalTime(PRESET_TYPES.WEEKS)).toBe(TWO_WEEKS);
    });
  });

  describe('getTimeOffset', () => {
    it('calculates the correct time offest', () => {
      const timelineStartDate = new Date('2021-01-13T00:00:00.000Z');
      const offset = getTimeOffset(timelineStartDate, mockShift);
      expect(offset).toBe(TWELVE_HOURS);
    });
  });

  describe('getDuration', () => {
    it('calculates the correct duration', () => {
      const duration = getDuration(mockShift);
      expect(duration).toBe(EIGHT_HOURS); // 8 hours
    });
  });

  describe('getPixelOffset', () => {
    it('calculates the correct pixel offest', () => {
      const timelineWidth = 1000;
      const presetType = PRESET_TYPES.DAYS;
      const pixelOffset = getPixelOffset({
        timeframe,
        shift: mockShift,
        timelineWidth,
        presetType,
      });
      expect(pixelOffset).toBe(500); // midday = half the total width
    });
  });

  describe('getShiftContainerStyles', () => {
    it('calculates the correct pixel width', () => {
      const timelineWidth = 1200; // 50 pixels per hour
      const presetType = PRESET_TYPES.DAYS;
      const containerStyles = getShiftContainerStyles({
        timeframe,
        presetType,
        timelineWidth,
        shift: mockShift,
      });
      expect(containerStyles).toStrictEqual({
        left: `600px`,
        width: `400px`,
      });
    });
  });
});
