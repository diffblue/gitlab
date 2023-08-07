import {
  setCronTime,
  parseCronTime,
  findFirstNumberInCronString,
  DAYS,
  HOUR_MINUTE_LIST,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/lib';

describe('Crone time', () => {
  describe('setCronTime', () => {
    it.each`
      day          | time | expectedResult
      ${0}         | ${0} | ${'0 0 * * *'}
      ${1}         | ${1} | ${'0 1 * * 1'}
      ${6}         | ${6} | ${'0 6 * * 6'}
      ${undefined} | ${1} | ${'0 1 * * *'}
    `('should set day and time for cron string', ({ day, time, expectedResult }) => {
      expect(setCronTime({ day, time })).toEqual(expectedResult);
    });
  });

  describe('parseCronTime', () => {
    it.each`
      croneString      | expectedResult
      ${'0 0 * * *'}   | ${{ day: DAYS[0], dayIndex: 0, time: HOUR_MINUTE_LIST[0], timeIndex: '0' }}
      ${'0 1 * * 4'}   | ${{ day: DAYS[4], dayIndex: '4', time: HOUR_MINUTE_LIST[1], timeIndex: '1' }}
      ${'0 a * * sas'} | ${{ day: DAYS[0], dayIndex: 0, time: HOUR_MINUTE_LIST[0], timeIndex: 0 }}
    `('should parse cron string correctly', ({ croneString, expectedResult }) => {
      expect(parseCronTime(croneString)).toEqual(expectedResult);
    });
  });

  describe('findFirstNumberInCronString', () => {
    it.each`
      cronString          | expectedResult
      ${'0 2 * * *'}      | ${'2'}
      ${'0 112323 * * 4'} | ${'112323'}
      ${'0 12sdd4 * * 0'} | ${'12'}
      ${'0 14sdd4 * * 0'} | ${'14'}
      ${'0 as * * 12'}    | ${''}
    `('find first number in cron string', ({ cronString, expectedResult }) => {
      expect(findFirstNumberInCronString(cronString)).toEqual(expectedResult);
    });
  });
});
