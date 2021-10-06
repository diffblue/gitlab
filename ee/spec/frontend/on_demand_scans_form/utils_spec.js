import { toGraphQLCadence, fromGraphQLCadence } from 'ee/on_demand_scans_form/utils';

describe('On-demand scans utils', () => {
  describe('toGraphQLCadence', () => {
    it.each(['', null, undefined])('returns an empty object if argument is falsy', (argument) => {
      expect(toGraphQLCadence(argument)).toEqual({});
    });

    it.each`
      input        | expectedOutput
      ${'UNIT_1'}  | ${{ unit: 'UNIT', duration: 1 }}
      ${'MONTH_3'} | ${{ unit: 'MONTH', duration: 3 }}
    `('properly computes $input', ({ input, expectedOutput }) => {
      expect(toGraphQLCadence(input)).toEqual(expectedOutput);
    });
  });

  describe('fromGraphQLCadence', () => {
    it.each(['', null, undefined, {}, { unit: null, duration: null }])(
      'returns an empty string if argument is invalid',
      (argument) => {
        expect(fromGraphQLCadence(argument)).toBe('');
      },
    );

    it.each`
      input                             | expectedOutput
      ${{ unit: 'UNIT', duration: 1 }}  | ${'UNIT_1'}
      ${{ unit: 'MONTH', duration: 3 }} | ${'MONTH_3'}
    `('properly computes $input', ({ input, expectedOutput }) => {
      expect(fromGraphQLCadence(input)).toEqual(expectedOutput);
    });
  });
});
