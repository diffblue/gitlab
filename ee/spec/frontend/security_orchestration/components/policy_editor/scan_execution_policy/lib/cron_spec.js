import {
  setCroneTime,
  parseCroneTime,
  DAYS,
  HOUR_MINUTE_LIST,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';

describe('Crone time', () => {
  describe('setCroneTime', () => {
    it.each`
      day          | time | expectedResult
      ${0}         | ${0} | ${'0 0 * * *'}
      ${1}         | ${1} | ${'0 1 * * 1'}
      ${6}         | ${6} | ${'0 6 * * 6'}
      ${undefined} | ${1} | ${'0 1 * * *'}
    `('should set day and time for crone string', ({ day, time, expectedResult }) => {
      expect(setCroneTime({ day, time })).toEqual(expectedResult);
    });
  });

  describe('parseCroneTime', () => {
    it.each`
      croneString      | expectedResult
      ${'0 0 * * *'}   | ${{ day: DAYS[0], time: HOUR_MINUTE_LIST[0] }}
      ${'0 1 * * 4'}   | ${{ day: DAYS[4], time: HOUR_MINUTE_LIST[1] }}
      ${'0 a * * sas'} | ${{ day: DAYS[0], time: HOUR_MINUTE_LIST[0] }}
    `('should parse crone string correctly', ({ croneString, expectedResult }) => {
      expect(parseCroneTime(croneString)).toEqual(expectedResult);
    });
  });
});
