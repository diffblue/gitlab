import * as cssVariables from '@gitlab/ui/scss_to_js/scss_variables';
import { startCase } from 'lodash';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { newDateAsLocaleTime } from '~/lib/utils/datetime_utility';
import { sprintf, __ } from '~/locale';
import { ASSIGNEE_COLORS_COMBO, LIGHT_TO_DARK_MODE_SHADE_MAPPING } from '../constants';

/**
 * Returns formatted timezone string, e.g. (UTC-09:00) AKST Alaska
 *
 * @param {Object} tz
 * @param {String} tz.name
 * @param {String} tz.formatted_offset
 * @param {String} tz.abbr
 *
 * @returns {String}
 */
export const getFormattedTimezone = (tz) => {
  return sprintf(__('(UTC %{offset}) %{timezone}'), {
    offset: tz.formatted_offset,
    timezone: `${tz.abbr} ${tz.name}`,
  });
};

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
export const getParticipantsForSave = (participants) =>
  participants.map(({ username, colorWeight, colorPalette }) => ({
    username,
    // eslint-disable-next-line @gitlab/require-i18n-strings
    colorWeight: `WEIGHT_${colorWeight}`,
    colorPalette: colorPalette.toUpperCase(),
  }));

/**
 * Returns user data along with user token styles - color of the text
 * as well as the token background color depending on light or dark mode
 *
 * @template User
 * @param {User} user
 *
 * @returns {Object}
 * @property {User}
 * @property {string} class (CSS) for text color
 * @property {string} styles for token background color
 */
export const getUserTokenStyles = (user) => {
  const { colorWeight, colorPalette } = user;
  const isDarkMode = darkModeEnabled();
  const modeColorWeight = isDarkMode ? LIGHT_TO_DARK_MODE_SHADE_MAPPING[colorWeight] : colorWeight;
  const bgColor = `dataViz${startCase(colorPalette)}${modeColorWeight}`;

  let textClass = 'gl-text-white';

  if (isDarkMode) {
    const medianColorPaletteWeight = 500;
    textClass = modeColorWeight < medianColorPaletteWeight ? 'gl-text-white' : 'gl-text-gray-900';
  }

  return {
    ...user,
    class: textClass,
    style: { backgroundColor: cssVariables[bgColor] },
  };
};

/**
 * Sets colorWeight and colorPalette for all participants options taking into account saved participants colors
 * so that there will be no color overlap
 *
 * @param {Object[]} allParticipants
 * @param {Object[]} selectedParticipants
 *
 * @returns {Object[]} A list of all participants with colorWeight and colorPalette properties set
 */
export const setParticipantsColors = (allParticipants, selectedParticipants = []) => {
  // filter out the colors that saved participants have assigned
  // so there are no duplicate colors
  let availableColors = ASSIGNEE_COLORS_COMBO.filter(({ colorWeight, colorPalette }) =>
    selectedParticipants.every(
      ({ colorWeight: weight, colorPalette: palette }) =>
        !(colorWeight === weight && colorPalette === palette),
    ),
  );

  // if all colors are exhausted, we allow to pick from the whole palette
  if (!availableColors.length) {
    availableColors = ASSIGNEE_COLORS_COMBO;
  }

  // filter out participants that were not saved previously and have no color info assigned
  // and assign each one an available color set
  const participants = allParticipants
    .filter((participant) =>
      selectedParticipants.every(({ user: { username } }) => username !== participant.username),
    )
    .map((participant, index) => {
      const colorIndex = index % availableColors.length;
      const { colorWeight, colorPalette } = availableColors[colorIndex];

      return {
        ...participant,
        colorWeight,
        colorPalette,
      };
    });

  return [
    ...participants,
    ...selectedParticipants.map(({ user, colorWeight, colorPalette }) => ({
      ...user,
      colorWeight,
      colorPalette,
    })),
  ].map(getUserTokenStyles);
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
