import { PRESET_TYPES } from 'ee/oncall_schedules/constants';

// New utils, unused for now. Added as part of the
// https://gitlab.com/gitlab-org/gitlab/-/issues/324608 merge train.

/**
 * Returns a specified time value as milliseconds.
 *
 * @param {Object} input data
 * @return {Number} the time value in milliseconds
 */
export const milliseconds = ({ h = 0, m = 0, s = 0 }) => (h * 60 * 60 + m * 60 + s) * 1000;

/**
 * Returns the start date of a shift in milliseconds
 *
 * @param {IncidentManagementOncallShift} shift
 * @return {Number} start date in milliseconds
 */
export const getAbsoluteStartDate = ({ startsAt }) => {
  return new Date(startsAt).getTime();
};

/**
 * Returns the end date of a shift in milliseconds
 *
 * @param {IncidentManagementOncallShift} shift
 * @return {Number} end date in milliseconds
 */
export const getAbsoluteEndDate = ({ endsAt }) => {
  return new Date(endsAt).getTime();
};

/**
 * Returns the length of the timeline in milliseconds
 *
 * @param {Enum} presetType
 * @return {Number} timeline length in milliseconds
 */
export const getTotalTime = (presetType) => {
  const MS_PER_DAY = milliseconds({ h: 24 });
  return presetType === PRESET_TYPES.DAYS ? MS_PER_DAY : MS_PER_DAY * 14; // Either 1 day or two weeks
};

/**
 * Returns the time difference between the beginning of the timeline and the beginning of a shift
 *
 * @param {Date} timelineStartDate
 * @param {IncidentManagementOncallShift} shift
 * @return {Number} offset in milliseconds
 */
export const getTimeOffset = (timelineStartDate, shift) => {
  return getAbsoluteStartDate(shift) - timelineStartDate.getTime();
};

/**
 * Returns the duration of a shift in milliseconds
 *
 * @param {IncidentManagementOncallShift} shift
 * @return {Number} duration in milliseconds
 */
export const getDuration = (shift) => {
  return getAbsoluteEndDate(shift) - getAbsoluteStartDate(shift);
};

/**
 * Returns the pixel distance between the beginning of the timeline and the beginning of a shift
 *
 * @param {Object} timeframe, shift, timelineWidth, presetType
 * @return {Number} distance in pixels
 */
export const getPixelOffset = ({ timeframe, shift, timelineWidth, presetType }) => {
  const totalTime = getTotalTime(presetType);
  const timeOffset = getTimeOffset(timeframe[0], shift);
  // offset (px) = total width (px) * shift time (ms) / total time (ms)
  return (timelineWidth * timeOffset) / totalTime;
};

/**
 * Returns the width of a shift in pixels
 *
 * @param {Object} shift, timelineWidth, presetType, shiftDLSOffset
 * @return {Number} width in pixels
 */
const getPixelWidth = ({ shift, timelineWidth, presetType }) => {
  const displayRangeTotal = getTotalTime(presetType);
  const durationMillis = getDuration(shift);
  const shiftDayListSavingsOffset =
    new Date(shift.startsAt).getTimezoneOffset() - new Date(shift.endsAt).getTimezoneOffset();
  const DLS = milliseconds({ m: shiftDayListSavingsOffset });
  // shift width (px) = shift time (ms) * total width (px) / total time (ms)
  return Math.round(((durationMillis + DLS) * timelineWidth) / displayRangeTotal);
};

export const getShiftContainerStyles = ({ timeframe, presetType, timelineWidth, shift }) => {
  const left = getPixelOffset({
    timeframe,
    shift,
    timelineWidth,
    presetType,
  });
  const width = getPixelWidth({
    shift,
    timelineWidth,
    presetType,
  });

  return {
    left: `${left}px`,
    width: `${width}px`,
  };
};
