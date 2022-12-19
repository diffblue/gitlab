import * as cssVariables from '@gitlab/ui/scss_to_js/scss_variables';
import { startCase } from 'lodash';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { newDateAsLocaleTime } from '~/lib/utils/datetime_utility';
import {
  ASSIGNEE_COLORS_COMBO,
  LIGHT_TO_DARK_MODE_SHADE_MAPPING,
  NON_ACTIVE_PARTICIPANT_STYLE,
} from '../constants';

/**
 * Returns `true` for non-empty string, otherwise returns `false`
 *
 * @param {String} startDate
 *
 * @returns {Boolean}
 */
export const isNameFieldValid = (nameField) => {
  return Boolean(nameField?.length);
};

/**
 * Returns user data along with user token styles - color of the text
 * as well as the token background color depending on light or dark mode
 *
 * @param {Object}
 * @property {string} colorWeight
 * @property {string} colorPalette
 *
 * @returns {Object}
 * @property {string} colorWeight
 * @property {string} colorPalette
 * @property {string} textClass (CSS) for text color
 * @property {string} backgroundStyle for background color
 */
export const getShiftStyles = ({ colorWeight, colorPalette }) => {
  const isDarkMode = darkModeEnabled();
  const modeColorWeight = isDarkMode ? LIGHT_TO_DARK_MODE_SHADE_MAPPING[colorWeight] : colorWeight;
  const bgColor = `dataViz${startCase(colorPalette)}${modeColorWeight}`;

  let textClass = 'gl-text-white';

  if (isDarkMode) {
    const medianColorPaletteWeight = 500;
    textClass = modeColorWeight < medianColorPaletteWeight ? 'gl-text-white' : 'gl-text-gray-900';
  }

  return {
    textClass,
    backgroundStyle: { backgroundColor: cssVariables[bgColor] },
  };
};

/**
 *
 * @param {number} participantIndex
 * @returns {Object}
 * @property {string} colorWeight
 * @property {string} colorPalette
 * @property {string} textClass (CSS) for text color
 * @property {Object} backgroundStyle for background color
 *  */
export const getParticipantColor = (participantIndex) => {
  if (participantIndex === -1) return NON_ACTIVE_PARTICIPANT_STYLE;

  const colorIndexReference = participantIndex % ASSIGNEE_COLORS_COMBO.length;

  return getShiftStyles(ASSIGNEE_COLORS_COMBO[colorIndexReference]);
};

/**
 * Returns a Array of Objects that represent the shift participant
 * with his/her username and unique shift color values
 *
 * @param {Object[]} participants
 *
 * @returns {Object[]} A list of values to save each participant
 * @property {string} username
 * @property {string} colorWeight
 * @property {string} colorPalette
 */
export const getParticipantsForSave = (participants) => {
  /**
   * Todo: Remove getParticipantsForSave once styling is no longer
   * required in API. See https://gitlab.com/gitlab-org/gitlab/-/issues/344950
   */

  const TEMP_DEFAULT_COLOR_WEIGHT = 'WEIGHT_500';
  const TEMP_DEFAULT_COLOR_PALLET = 'BLUE';

  return participants.map(({ username }) => ({
    username,
    colorWeight: TEMP_DEFAULT_COLOR_WEIGHT,
    colorPalette: TEMP_DEFAULT_COLOR_PALLET,
  }));
};

/**
 * Parses a activePeriod string into an integer value
 *
 * @param {String} hourString
 */
export const parseHour = (hourString) => parseInt(hourString.slice(0, 2), 10);

/**
 * Parses a rotation date for use in the add/edit rotation form
 *
 * @param {ISOString} dateTimeString
 * @param {Timezone string - long} scheduleTimezone
 */
export const parseRotationDate = (dateTimeString, scheduleTimezone) => {
  const options = {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    hourCycle: 'h23',
    timeZone: scheduleTimezone,
    timeZoneName: 'long',
  };
  const formatter = new Intl.DateTimeFormat('en-US', options);
  const parts = formatter.formatToParts(Date.parse(dateTimeString));
  const [month, , day, , year, , hour] = parts.map((part) => part.value);
  // The datepicker uses local time
  const date = newDateAsLocaleTime(`${year}-${month}-${day}`);
  const time = parseInt(hour, 10);

  return { date, time };
};

/**
 * Renames keys to be read by gl-token-selector
 * @param {Object[]} participants
 *
 * @returns {Object}
 * @property {Object} user
 * @property {string} class (CSS) for text color
 * @property {string} styles for token background color
 *
 */
export const formatParticipantsForTokenSelector = (participants) => {
  return participants.map((item, index) => {
    const { textClass, backgroundStyle } = getParticipantColor(index);

    return {
      ...item,
      class: textClass,
      style: backgroundStyle,
    };
  });
};
