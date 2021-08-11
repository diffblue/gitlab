import {
  getFormattedTimezone,
  getParticipantsForSave,
  parseHour,
  parseRotationDate,
  getUserTokenStyles,
  setParticipantsColors,
} from 'ee/oncall_schedules/utils/common_utils';
import * as ColorUtils from '~/lib/utils/color_utils';
import mockTimezones from './mocks/mock_timezones.json';

describe('getFormattedTimezone', () => {
  it('formats the timezone', () => {
    const tz = mockTimezones[0];
    const expectedValue = `(UTC ${tz.formatted_offset}) ${tz.abbr} ${tz.name}`;
    expect(getFormattedTimezone(tz)).toBe(expectedValue);
  });
});

describe('getParticipantsForSave', () => {
  it('returns participant shift color data along with the username', () => {
    const participants = [
      { username: 'user1', colorWeight: 300, colorPalette: 'blue', extraProp: '1' },
      { username: 'user2', colorWeight: 400, colorPalette: 'red', extraProp: '2' },
      { username: 'user3', colorWeight: 500, colorPalette: 'green', extraProp: '4' },
    ];
    const expectedParticipantsForSave = [
      { username: 'user1', colorWeight: 'WEIGHT_300', colorPalette: 'BLUE' },
      { username: 'user2', colorWeight: 'WEIGHT_400', colorPalette: 'RED' },
      { username: 'user3', colorWeight: 'WEIGHT_500', colorPalette: 'GREEN' },
    ];
    expect(getParticipantsForSave(participants)).toEqual(expectedParticipantsForSave);
  });
});

describe('getUserTokenStyles', () => {
  it.each`
    isDarkMode | colorWeight | expectedTextClass     | expectedBackgroundColor
    ${true}    | ${900}      | ${'gl-text-white'}    | ${'#d4dcfa'}
    ${true}    | ${500}      | ${'gl-text-gray-900'} | ${'#5772ff'}
    ${false}   | ${400}      | ${'gl-text-white'}    | ${'#748eff'}
    ${false}   | ${700}      | ${'gl-text-white'}    | ${'#3547de'}
  `(
    'sets correct styles and class',
    ({ isDarkMode, colorWeight, expectedTextClass, expectedBackgroundColor }) => {
      jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => isDarkMode);

      const user = { username: 'user1', colorWeight, colorPalette: 'blue' };

      expect(getUserTokenStyles(user)).toMatchObject({
        class: expectedTextClass,
        style: { backgroundColor: expectedBackgroundColor },
      });
    },
  );
});

describe('setParticipantsColors', () => {
  it('sets token color data to each of the eparticipant', () => {
    jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => false);

    const allParticpants = [
      { username: 'user1' },
      { username: 'user2' },
      { username: 'user3' },
      { username: 'user4' },
      { username: 'user5' },
      { username: 'user6' },
    ];
    const selectedParticpants = [
      { user: { username: 'user2' }, colorPalette: 'blue', colorWeight: '500' },
      { user: { username: 'user4' }, colorPalette: 'magenta', colorWeight: '500' },
      { user: { username: 'user5' }, colorPalette: 'orange', colorWeight: '500' },
    ];
    const expectedParticipants = [
      {
        username: 'user1',
        colorWeight: '500',
        colorPalette: 'aqua',
        class: 'gl-text-white',
        style: { backgroundColor: '#0094b6' },
      },
      {
        username: 'user3',
        colorWeight: '500',
        colorPalette: 'green',
        class: 'gl-text-white',
        style: { backgroundColor: '#608b2f' },
      },
      {
        username: 'user6',
        colorWeight: '600',
        colorPalette: 'blue',
        class: 'gl-text-white',
        style: { backgroundColor: '#445cf2' },
      },
      {
        username: 'user2',
        colorWeight: '500',
        colorPalette: 'blue',
        class: 'gl-text-white',
        style: { backgroundColor: '#5772ff' },
      },
      {
        username: 'user4',
        colorWeight: '500',
        colorPalette: 'magenta',
        class: 'gl-text-white',
        style: { backgroundColor: '#d84280' },
      },
      {
        username: 'user5',
        colorWeight: '500',
        colorPalette: 'orange',
        class: 'gl-text-white',
        style: { backgroundColor: '#d14e00' },
      },
    ];
    expect(setParticipantsColors(allParticpants, selectedParticpants)).toEqual(
      expectedParticipants,
    );
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
