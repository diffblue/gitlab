import { getIterationPeriod, groupByIterationCadences } from 'ee/iterations/utils';
import {
  mockIterationNode,
  mockIterationsWithCadences,
  mockIterationsWithoutCadences,
} from './mock_data';

describe('getIterationPeriod', () => {
  it('returns time period given an iteration', () => {
    expect(getIterationPeriod(mockIterationNode)).toBe('Feb 10, 2021 - Feb 17, 2021');
  });
});

describe('groupByIterationCadences', () => {
  const period = 'Nov 23, 2021 - Nov 30, 2021';
  const expected = [
    {
      id: 1,
      title: 'cadence 1',
      iterations: [
        { id: 1, title: 'iteration 1', period },
        { id: 4, title: 'iteration 4', period },
      ],
    },
    {
      id: 2,
      title: 'cadence 2',
      iterations: [
        { id: 2, title: 'iteration 2', period },
        { id: 3, title: 'iteration 3', period },
      ],
    },
  ];

  it('groups iterations by cadence', () => {
    expect(groupByIterationCadences(mockIterationsWithCadences)).toStrictEqual(expected);
  });

  it('returns empty array when iterations do not have cadences', () => {
    expect(groupByIterationCadences(mockIterationsWithoutCadences)).toEqual([]);
  });

  it('returns empty array when passed an empty array', () => {
    expect(groupByIterationCadences([])).toEqual([]);
  });
});
