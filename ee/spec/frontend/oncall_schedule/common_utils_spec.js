import {
  getParticipantsForSave,
  parseHour,
  parseRotationDate,
  getShiftStyles,
  getParticipantColor,
  formatParticipantsForTokenSelector,
} from 'ee/oncall_schedules/utils/common_utils';
import { ASSIGNEE_COLORS_COMBO } from 'ee/oncall_schedules/constants';
import * as ColorUtils from '~/lib/utils/color_utils';
import { mockParticipants } from './mock_data';

describe('getParticipantsForSave', () => {
  /**
   * Todo: Remove getParticipantsForSave once styling is no longer
   * required in API. See https://gitlab.com/gitlab-org/gitlab/-/issues/344950
   */
  it('returns participant shift color data along with the username', () => {
    const expectedParticipantsForSave = [
      { username: mockParticipants[0].username, colorWeight: 'WEIGHT_500', colorPalette: 'BLUE' },
      { username: mockParticipants[1].username, colorWeight: 'WEIGHT_500', colorPalette: 'BLUE' },
      { username: mockParticipants[2].username, colorWeight: 'WEIGHT_500', colorPalette: 'BLUE' },
      { username: mockParticipants[3].username, colorWeight: 'WEIGHT_500', colorPalette: 'BLUE' },
      { username: mockParticipants[4].username, colorWeight: 'WEIGHT_500', colorPalette: 'BLUE' },
      { username: mockParticipants[5].username, colorWeight: 'WEIGHT_500', colorPalette: 'BLUE' },
    ];
    expect(getParticipantsForSave(mockParticipants)).toEqual(expectedParticipantsForSave);
  });
});

describe('getShiftStyles', () => {
  it.each`
    isDarkMode | colorWeight | expectedTextClass     | expectedBackgroundColor
    ${true}    | ${900}      | ${'gl-text-white'}    | ${'#d2dcff'}
    ${true}    | ${500}      | ${'gl-text-gray-900'} | ${'#617ae2'}
    ${false}   | ${400}      | ${'gl-text-white'}    | ${'#7992f5'}
    ${false}   | ${700}      | ${'gl-text-white'}    | ${'#3f51ae'}
  `(
    'sets correct styles and class',
    ({ isDarkMode, colorWeight, expectedTextClass, expectedBackgroundColor }) => {
      jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => isDarkMode);

      const user = { colorWeight, colorPalette: 'blue' };

      expect(getShiftStyles(user)).toMatchObject({
        textClass: expectedTextClass,
        backgroundStyle: { backgroundColor: expectedBackgroundColor },
      });
    },
  );
});

describe('getParticipantColor', () => {
  jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => false);

  it.each`
    isDarkMode | colorWeight | expectedTextClass     | expectedBackgroundColor
    ${true}    | ${900}      | ${'gl-text-white'}    | ${'#d2dcff'}
    ${true}    | ${500}      | ${'gl-text-gray-900'} | ${'#617ae2'}
    ${false}   | ${400}      | ${'gl-text-white'}    | ${'#7992f5'}
    ${false}   | ${700}      | ${'gl-text-white'}    | ${'#3f51ae'}
  `(
    'sets correct styles and class',
    ({ isDarkMode, colorWeight, expectedTextClass, expectedBackgroundColor }) => {
      jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => isDarkMode);

      const userColors = { colorWeight, colorPalette: 'blue' };

      expect(getShiftStyles(userColors)).toMatchObject({
        textClass: expectedTextClass,
        backgroundStyle: { backgroundColor: expectedBackgroundColor },
      });
    },
  );

  it('sets token colors for each participant', () => {
    const createParticipantsList = (numberOfParticipants) =>
      new Array(numberOfParticipants)
        .fill(undefined)
        .map((item, index) => ({ username: `user${index + 1}`, ...item }));
    const participants = createParticipantsList(6);

    const expectedParticipants = [
      {
        textClass: 'gl-text-white',
        backgroundStyle: { backgroundColor: '#617ae2' },
      },
      {
        textClass: 'gl-text-white',
        backgroundStyle: { backgroundColor: '#c95d2e' },
      },
      {
        textClass: 'gl-text-white',
        backgroundStyle: { backgroundColor: '#0090b1' },
      },
      {
        textClass: 'gl-text-white',
        backgroundStyle: { backgroundColor: '#619025' },
      },
      {
        textClass: 'gl-text-white',
        backgroundStyle: { backgroundColor: '#cf4d81' },
      },
      {
        textClass: 'gl-text-white',
        backgroundStyle: { backgroundColor: '#4e65cd' },
      },
    ];

    expect(participants.map((item, index) => getParticipantColor(index))).toEqual(
      expectedParticipants,
    );
  });

  it('when all colors are exhausted it uses the first color in list again', () => {
    jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => false);

    const numberOfColorCombinations = ASSIGNEE_COLORS_COMBO.length;

    const lastParticipantColor = {
      textClass: 'gl-text-white',
      backgroundStyle: { backgroundColor: '#617ae2' },
    };

    expect(getParticipantColor(numberOfColorCombinations)).toEqual(lastParticipantColor);
  });
});

describe('parseRotationDate', () => {
  const scheduleTimezone = 'Pacific/Honolulu'; // UTC -10

  it('parses a rotation date according to the supplied timezone', () => {
    const dateTimeString = '2021-01-12T05:04:56.333Z';
    const rotationDate = parseRotationDate(dateTimeString, scheduleTimezone);

    expect(rotationDate).toStrictEqual({ date: new Date('2021-01-11T00:00:00.000Z'), time: 19 });
  });

  it('parses a rotation date at midnight without exceeding 24 hours', () => {
    const dateTimeString = '2021-01-12T10:00:00.000Z';
    const rotationDate = parseRotationDate(dateTimeString, scheduleTimezone);

    expect(rotationDate).toStrictEqual({ date: new Date('2021-01-12T00:00:00.000Z'), time: 0 });
  });
});

describe('parseHour', () => {
  it('parses a rotation active period hour string', () => {
    const hourString = '14:00';

    const hourInt = parseHour(hourString);

    expect(hourInt).toBe(14);
  });
});

describe('formatParticipantsForTokenSelector', () => {
  it('formats participants in light mode', () => {
    jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => false);
    const formattedParticipants = formatParticipantsForTokenSelector(mockParticipants);

    const expected = [
      {
        ...mockParticipants[0],
        class: 'gl-text-white',
        style: { backgroundColor: '#617ae2' },
      },
      {
        ...mockParticipants[1],
        class: 'gl-text-white',
        style: { backgroundColor: '#c95d2e' },
      },
      {
        ...mockParticipants[2],
        class: 'gl-text-white',
        style: { backgroundColor: '#0090b1' },
      },
      {
        ...mockParticipants[3],
        class: 'gl-text-white',
        style: { backgroundColor: '#619025' },
      },
      {
        ...mockParticipants[4],
        class: 'gl-text-white',
        style: { backgroundColor: '#cf4d81' },
      },
      {
        ...mockParticipants[5],
        class: 'gl-text-white',
        style: { backgroundColor: '#4e65cd' },
      },
    ];

    expect(formattedParticipants).toStrictEqual(expected);
  });

  it('formats participants in dark mode', () => {
    jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => true);
    const formattedParticipants = formatParticipantsForTokenSelector(mockParticipants);

    const expected = [
      {
        ...mockParticipants[0],
        class: 'gl-text-gray-900',
        style: { backgroundColor: '#617ae2' },
      },
      {
        ...mockParticipants[1],
        class: 'gl-text-gray-900',
        style: { backgroundColor: '#c95d2e' },
      },
      {
        ...mockParticipants[2],
        class: 'gl-text-gray-900',
        style: { backgroundColor: '#0090b1' },
      },
      {
        ...mockParticipants[3],
        class: 'gl-text-gray-900',
        style: { backgroundColor: '#619025' },
      },
      {
        ...mockParticipants[4],
        class: 'gl-text-gray-900',
        style: { backgroundColor: '#cf4d81' },
      },
      {
        ...mockParticipants[5],
        class: 'gl-text-white',
        style: { backgroundColor: '#7992f5' },
      },
    ];

    expect(formattedParticipants).toStrictEqual(expected);
  });
});
