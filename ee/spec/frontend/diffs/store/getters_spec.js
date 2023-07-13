import * as getters from 'ee/diffs/store/getters';
import state from 'ee/diffs/store/modules/diff_state';

describe('EE Diffs Module Getters', () => {
  let localState;

  describe('fileLineCodequality', () => {
    beforeEach(() => {
      localState = state();

      localState.codequalityDiff = {
        files: {
          'index.js': [
            {
              severity: 'minor',
              description: 'Unexpected alert.',
              line: 1,
            },
            {
              severity: 'major',
              description:
                'Function `aVeryLongFunction` has 52 lines of code (exceeds 25 allowed). Consider refactoring.',
              line: 3,
            },
            {
              severity: 'minor',
              description: 'Arrow function has too many statements (52). Maximum allowed is 30.',
              line: 3,
            },
          ],
        },
      };
    });

    it.each`
      line | severity
      ${1} | ${'minor'}
      ${2} | ${'no'}
      ${3} | ${'major'}
      ${4} | ${'no'}
    `('finds $severity degradation on line $line', ({ line, severity }) => {
      if (severity === 'no') {
        expect(getters.fileLineCodequality(localState)('index.js', line)).toEqual([]);
      } else {
        expect(getters.fileLineCodequality(localState)('index.js', line)[0]).toMatchObject({
          line,
          severity,
        });
      }
    });
  });

  describe('fileLineSast', () => {
    beforeEach(() => {
      localState = state();

      localState.sastDiff = {
        added: [
          {
            description:
              'Second finding Markup escaping disabled. This can be used with some template engines to escape\ndisabling of HTML entities, which can lead to XSS attacks.\n',
            severity: 'low',
            location: {
              file: 'index.js',
              start_line: 1,
            },
          },
          {
            description:
              'Second finding Markup escaping disabled. This can be used with some template engines to escape\ndisabling of HTML entities, which can lead to XSS attacks.\n',
            severity: 'medium',
            location: {
              file: 'index.js',
              start_line: 3,
            },
          },
        ],
      };
    });

    it.each`
      line | severity
      ${1} | ${'low'}
      ${2} | ${'no'}
      ${3} | ${'medium'}
      ${4} | ${'no'}
    `('finds $severity degradation on line $line', ({ line, severity }) => {
      if (severity === 'no') {
        expect(getters.fileLineSast(localState)('index.js', line)).toEqual([]);
      } else {
        expect(getters.fileLineSast(localState)('index.js', line)[0]).toMatchObject({
          line,
          severity,
        });
      }
    });
  });
});
