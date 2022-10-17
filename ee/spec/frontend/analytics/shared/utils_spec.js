import {
  buildGroupFromDataset,
  buildProjectFromDataset,
  buildCycleAnalyticsInitialData,
  buildNullSeries,
  toLocalDate,
  pairDataAndLabels,
} from 'ee/analytics/shared/utils';

const rawValueStream = `{
  "id": 1,
  "name": "Custom value stream 1",
  "is_custom": true
}`;

const groupDataset = {
  groupId: '1',
  groupName: 'My Group',
  groupFullPath: 'my-group',
  groupAvatarUrl: 'foo/bar',
};

const subGroupDataset = {
  groupId: '1',
  groupName: 'My Group',
  groupFullPath: 'parent/my-group',
  groupAvatarUrl: 'foo/bar',
  groupParentId: 20,
};

const projectDataset = {
  projectId: '1',
  projectGid: 'gid://gitlab/Project/1',
  projectName: 'My Project',
  projectPathWithNamespace: 'my-group/my-project',
};

const rawProjects = `[
  {
    "project_id": "1",
    "project_name": "My Project",
    "project_path_with_namespace": "my-group/my-project"
  }
]`;

const NO_DATA_MESSAGE = 'No data available';

describe('buildGroupFromDataset', () => {
  it('returns null if groupId is missing', () => {
    expect(buildGroupFromDataset({ foo: 'bar' })).toBeNull();
  });

  it('returns a group object when the groupId is given', () => {
    expect(buildGroupFromDataset(groupDataset)).toEqual({
      id: 1,
      name: 'My Group',
      full_path: 'my-group',
      avatar_url: 'foo/bar',
    });
  });

  it('sets the parent_id when a subgroup is given', () => {
    expect(buildGroupFromDataset(subGroupDataset)).toEqual({
      id: 1,
      name: 'My Group',
      full_path: 'parent/my-group',
      avatar_url: 'foo/bar',
      parent_id: 20,
    });
  });
});

describe('buildProjectFromDataset', () => {
  it('returns null if projectId is missing', () => {
    expect(buildProjectFromDataset({ foo: 'bar' })).toBeNull();
  });

  it('returns a project object when the projectId is given', () => {
    expect(buildProjectFromDataset(projectDataset)).toEqual({
      id: 'gid://gitlab/Project/1',
      name: 'My Project',
      path_with_namespace: 'my-group/my-project',
      avatar_url: undefined,
    });
  });
});

describe('toLocalDate', () => {
  it('returns a Date object', () => {
    const expectedDate = new Date(2022, 1, 10); // month is zero-based

    expect(toLocalDate('2022-02-10')).toEqual(expectedDate);
  });
});

describe('buildCycleAnalyticsInitialData', () => {
  it.each`
    field                 | value
    ${'group'}            | ${null}
    ${'createdBefore'}    | ${null}
    ${'createdAfter'}     | ${null}
    ${'selectedProjects'} | ${null}
    ${'labelsPath'}       | ${''}
    ${'milestonesPath'}   | ${''}
    ${'stage'}            | ${null}
  `('will set a default value for "$field" if is not present', ({ field, value }) => {
    expect(buildCycleAnalyticsInitialData()).toMatchObject({
      [field]: value,
    });
  });

  describe('value stream', () => {
    it('will be set given an array of projects', () => {
      expect(buildCycleAnalyticsInitialData({ valueStream: rawValueStream })).toMatchObject({
        selectedValueStream: {
          id: 1,
          name: 'Custom value stream 1',
          isCustom: true,
        },
      });
    });

    it.each`
      value
      ${null}
      ${''}
    `('will be null if given a value of `$value`', ({ value }) => {
      expect(buildCycleAnalyticsInitialData({ valueStream: value })).toMatchObject({
        selectedValueStream: null,
      });
    });
  });

  describe('group', () => {
    it("will be set given a valid 'groupId' and all group parameters", () => {
      expect(buildCycleAnalyticsInitialData(groupDataset)).toMatchObject({
        group: { avatarUrl: 'foo/bar', fullPath: 'my-group', id: 1, name: 'My Group' },
      });
    });

    it.each`
      field          | value
      ${'avatarUrl'} | ${null}
      ${'fullPath'}  | ${null}
      ${'name'}      | ${null}
      ${'parentId'}  | ${null}
    `("will be $value if the '$field' field is not present", ({ field, value }) => {
      expect(buildCycleAnalyticsInitialData({ groupId: groupDataset.groupId })).toMatchObject({
        group: { id: 1, [field]: value },
      });
    });
  });

  describe('selectedProjects', () => {
    it('will be set given an array of projects', () => {
      expect(buildCycleAnalyticsInitialData({ projects: rawProjects })).toMatchObject({
        selectedProjects: [
          {
            projectId: '1',
            projectName: 'My Project',
            projectPathWithNamespace: 'my-group/my-project',
          },
        ],
      });
    });

    it.each`
      field                 | value   | result
      ${'selectedProjects'} | ${null} | ${null}
      ${'selectedProjects'} | ${[]}   | ${[]}
      ${'selectedProjects'} | ${''}   | ${null}
    `('will be an empty array if given a value of `$value`', ({ value, field, result }) => {
      expect(buildCycleAnalyticsInitialData({ projects: value })).toMatchObject({
        [field]: result,
      });
    });
  });

  describe.each`
    field              | value
    ${'createdBefore'} | ${'2019-12-31'}
    ${'createdAfter'}  | ${'2019-10-31'}
  `('$field', ({ field, value }) => {
    it('given a valid date, will return a date object', () => {
      expect(buildCycleAnalyticsInitialData({ [field]: value })).toMatchObject({
        [field]: new Date(value),
      });
    });

    it('will return null if omitted', () => {
      expect(buildCycleAnalyticsInitialData()).toMatchObject({ [field]: null });
    });
  });
});

describe('buildNullSeries', () => {
  it('returns series data with the expected styles and text', () => {
    const inputSeries = [
      {
        name: 'Chart title',
        data: [],
      },
    ];

    const expectedSeries = [
      {
        name: NO_DATA_MESSAGE,
        data: expect.any(Array),
        showSymbol: false,
        lineStyle: {
          color: expect.any(String),
          type: 'dashed',
        },
        areaStyle: {
          color: 'none',
        },
        itemStyle: {
          color: expect.any(String),
        },
      },
      {
        name: 'Chart title',
        showAllSymbol: true,
        showSymbol: true,
        symbolSize: 8,
        data: expect.any(Array),
        lineStyle: {
          color: expect.any(String),
        },
        areaStyle: {
          opacity: 0,
        },
        itemStyle: {
          color: expect.any(String),
        },
      },
    ];

    expect(buildNullSeries({ seriesData: inputSeries, nullSeriesTitle: NO_DATA_MESSAGE })).toEqual(
      expectedSeries,
    );
  });

  describe('series data', () => {
    describe('non-empty series', () => {
      it('returns the provided non-empty series data unmodified as the second series', () => {
        const inputSeries = [
          {
            data: [
              ['Mar 1', 4],
              ['Mar 2', null],
              ['Mar 3', null],
              ['Mar 4', 10],
            ],
          },
        ];

        const actualSeries = buildNullSeries({
          seriesData: inputSeries,
          nullSeriesTitle: NO_DATA_MESSAGE,
        });

        expect(actualSeries[1]).toMatchObject(inputSeries[0]);
      });
    });

    describe('empty series', () => {
      const compareSeriesData = (inputSeriesData, expectedEmptySeriesData) => {
        const actualEmptySeriesData = buildNullSeries({
          seriesData: [{ data: inputSeriesData }],
          nullSeriesTitle: NO_DATA_MESSAGE,
        })[0].data;

        expect(actualEmptySeriesData).toEqual(expectedEmptySeriesData);
      };

      describe('when the data contains a gap in the middle of the data set', () => {
        it('builds the "no data" series by linealy interpolating between the provided data points', () => {
          const inputSeriesData = [
            ['Mar 1', 4],
            ['Mar 2', null],
            ['Mar 3', null],
            ['Mar 4', 10],
          ];

          const expectedEmptySeriesData = [
            ['Mar 1', 4],
            ['Mar 2', 6],
            ['Mar 3', 8],
            ['Mar 4', 10],
          ];

          compareSeriesData(inputSeriesData, expectedEmptySeriesData);
        });
      });

      describe('when the data contains a gap at the beginning of the data set', () => {
        it('fills in the gap using the first non-null data point value', () => {
          const inputSeriesData = [
            ['Mar 1', null],
            ['Mar 2', null],
            ['Mar 3', null],
            ['Mar 4', 10],
          ];

          const expectedEmptySeriesData = [
            ['Mar 1', 10],
            ['Mar 2', 10],
            ['Mar 3', 10],
            ['Mar 4', 10],
          ];

          compareSeriesData(inputSeriesData, expectedEmptySeriesData);
        });
      });

      describe('when the data contains a gap at the end of the data set', () => {
        it('fills in the gap using the last non-null data point value', () => {
          const inputSeriesData = [
            ['Mar 1', 10],
            ['Mar 2', null],
            ['Mar 3', null],
            ['Mar 4', null],
          ];

          const expectedEmptySeriesData = [
            ['Mar 1', 10],
            ['Mar 2', 10],
            ['Mar 3', 10],
            ['Mar 4', 10],
          ];

          compareSeriesData(inputSeriesData, expectedEmptySeriesData);
        });
      });

      describe('when the data contains all null values', () => {
        it('fills the empty series with all zeros', () => {
          const inputSeriesData = [
            ['Mar 1', null],
            ['Mar 2', null],
            ['Mar 3', null],
            ['Mar 4', null],
          ];

          const expectedEmptySeriesData = [
            ['Mar 1', 0],
            ['Mar 2', 0],
            ['Mar 3', 0],
            ['Mar 4', 0],
          ];

          compareSeriesData(inputSeriesData, expectedEmptySeriesData);
        });
      });
    });
  });
});

describe('pairDataAndLabels', () => {
  let result = [];

  const datasetNames = ['Dataset one', 'Dataset two'];
  const axisLabels = ['label 1', 'label 2', 'label 3'];
  const datasets = [{ data: ['a', 'b', 'c'] }, { data: ['d', 'e', 'f'] }];
  const expectedDatasets = [
    {
      name: datasetNames[0],
      data: [
        ['label 1', 'a'],
        ['label 2', 'b'],
        ['label 3', 'c'],
      ],
    },
    {
      name: datasetNames[1],
      data: [
        ['label 1', 'd'],
        ['label 2', 'e'],
        ['label 3', 'f'],
      ],
    },
  ];

  beforeEach(() => {
    result = pairDataAndLabels({ axisLabels, datasetNames, datasets });
  });

  afterEach(() => {
    result = null;
  });

  it('sets the correct dataset name for each dataset', () => {
    result.forEach(({ name }, index) => {
      expect(datasetNames[index]).toBe(name);
    });
  });

  it('pairs each data point with the relevant label', () => {
    result.forEach((res, index) => {
      expect(res).toEqual(expectedDatasets[index]);
    });
  });
});
