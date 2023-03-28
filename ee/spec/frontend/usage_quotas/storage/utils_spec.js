import {
  usageRatioToThresholdLevel,
  formatUsageSize,
  parseProjects,
  calculateUsedAndRemStorage,
  formatSizeAndSplit,
} from 'ee/usage_quotas/storage/utils';

import {
  projects as mockProjectsData,
  mockGetNamespaceStorageStatisticsGraphQLResponse,
} from './mock_data';

describe('UsageThreshold', () => {
  it.each`
    usageRatio | expectedLevel
    ${0}       | ${'none'}
    ${0.4}     | ${'none'}
    ${0.5}     | ${'info'}
    ${0.9}     | ${'info'}
    ${0.99}    | ${'alert'}
    ${1}       | ${'error'}
    ${1.5}     | ${'error'}
  `('returns $expectedLevel from $usageRatio', ({ usageRatio, expectedLevel }) => {
    expect(usageRatioToThresholdLevel(usageRatio)).toBe(expectedLevel);
  });
});

describe('formatUsageSize', () => {
  it.each`
    input             | expected
    ${0}              | ${'0.0KiB'}
    ${999}            | ${'1.0KiB'}
    ${1000}           | ${'1.0KiB'}
    ${10240}          | ${'10.0KiB'}
    ${1024 * 10 ** 5} | ${'97.7MiB'}
    ${10 ** 6}        | ${'976.6KiB'}
    ${1024 * 10 ** 6} | ${'976.6MiB'}
    ${10 ** 8}        | ${'95.4MiB'}
    ${1024 * 10 ** 8} | ${'95.4GiB'}
    ${10 ** 10}       | ${'9.3GiB'}
    ${10 ** 12}       | ${'931.3GiB'}
    ${10 ** 15}       | ${'909.5TiB'}
  `('returns $expected from $input', ({ input, expected }) => {
    expect(formatUsageSize(input)).toBe(expected);
  });

  it('render the output with unit separator when unitSeparator param is passed', () => {
    expect(formatUsageSize(1000, '-')).toBe('1.0-KiB');
    expect(formatUsageSize(1000, ' ')).toBe('1.0 KiB');
  });
});

describe('calculateUsedAndRemStorage', () => {
  it.each`
    description                                       | project                | purchasedStorageRemaining | totalCalculatedUsedStorage | totalCalculatedStorageLimit
    ${'project in error state and purchased 0'}       | ${mockProjectsData[0]} | ${0}                      | ${419430}                  | ${419430}
    ${'project in error state and purchased 10000'}   | ${mockProjectsData[0]} | ${100000}                 | ${419430}                  | ${519430}
    ${'project in warning state and purchased 0'}     | ${mockProjectsData[1]} | ${0}                      | ${0}                       | ${100000}
    ${'project in warning state and purchased 10000'} | ${mockProjectsData[1]} | ${100000}                 | ${0}                       | ${200000}
    ${'project within limit and purchased 0'}         | ${mockProjectsData[2]} | ${0}                      | ${41943}                   | ${100000}
    ${'project within limit and purchased 10000'}     | ${mockProjectsData[2]} | ${100000}                 | ${41943}                   | ${200000}
  `(
    'returns used: $totalCalculatedUsedStorage and remaining: $totalCalculatedStorageLimit storage for $description',
    ({
      project,
      purchasedStorageRemaining,
      totalCalculatedUsedStorage,
      totalCalculatedStorageLimit,
    }) => {
      const result = calculateUsedAndRemStorage(project, purchasedStorageRemaining);

      expect(result.totalCalculatedUsedStorage).toBe(totalCalculatedUsedStorage);
      expect(result.totalCalculatedStorageLimit).toBe(totalCalculatedStorageLimit);
    },
  );
});

describe('parseProjects', () => {
  it('ensures all projects have totalCalculatedUsedStorage and totalCalculatedStorageLimit', () => {
    const projects = parseProjects({
      projects: mockGetNamespaceStorageStatisticsGraphQLResponse.data.namespace.projects,
      additionalPurchasedStorageSize: 10000,
      totalRepositorySizeExcess: 5000,
    });

    projects.forEach((project) => {
      expect(project).toMatchObject({
        totalCalculatedUsedStorage: expect.any(Number),
        totalCalculatedStorageLimit: expect.any(Number),
      });
    });
  });
});

describe('formatSizeAndSplit', () => {
  it('returns null if passed parameter is null', () => {
    expect(formatSizeAndSplit(null)).toBe(null);
  });

  it('returns formatted size as object { value, unit }', () => {
    expect(formatSizeAndSplit(1000)).toEqual({ value: '1.0', unit: 'KiB' });
  });
});
