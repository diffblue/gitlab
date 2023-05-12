import { isNumber } from 'lodash';
import {
  isStartEvent,
  isLabelEvent,
  getAllowedEndEvents,
  eventToOption,
  eventsByIdentifier,
  getLabelEventsIdentifiers,
  flattenDurationChartData,
  getDurationChartData,
  getDurationOverviewChartData,
  transformRawStages,
  getTasksByTypeData,
  flattenTaskByTypeSeries,
  orderByDate,
  toggleSelectedLabel,
  prepareStageErrors,
  formatMedianValuesWithOverview,
  generateFilterTextDescription,
  groupDurationsByDay,
  formatDurationOverviewChartData,
} from 'ee/analytics/cycle_analytics/utils';
import {
  TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
  TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS,
} from 'ee/analytics/cycle_analytics/constants';
import {
  createdAfter,
  createdBefore,
  rawStageMedians,
} from 'jest/analytics/cycle_analytics/mock_data';
import { toYmd } from '~/analytics/shared/utils';
import { OVERVIEW_STAGE_ID } from '~/analytics/cycle_analytics/constants';
import { medianTimeToParsedSeconds } from '~/analytics/cycle_analytics/utils';
import { getDatesInRange, getDayDifference } from '~/lib/utils/datetime_utility';
import {
  customStageEvents as events,
  customStageLabelEvents as labelEvents,
  labelStartEvent,
  customStageStartEvents as startEvents,
  transformedDurationData,
  flattenedDurationData,
  durationChartPlottableData,
  durationOverviewChartPlottableData,
  issueStage,
  rawCustomStage,
  rawTasksByTypeData,
} from './mock_data';

const labelEventIds = labelEvents.map((ev) => ev.identifier);

describe('Value Stream Analytics utils', () => {
  describe('isStartEvent', () => {
    it('will return true for a valid start event', () => {
      expect(isStartEvent(startEvents[0])).toEqual(true);
    });

    it('will return false for input that is not a start event', () => {
      [{ identifier: 'fake-event', canBeStartEvent: false }, {}, [], null, undefined].forEach(
        (ev) => {
          expect(isStartEvent(ev)).toEqual(false);
        },
      );
    });
  });

  describe('isLabelEvent', () => {
    it('will return true if the given event identifier is in the labelEvents array', () => {
      expect(isLabelEvent(labelEventIds, labelStartEvent.identifier)).toEqual(true);
    });

    it('will return false if the given event identifier is not in the labelEvents array', () => {
      [startEvents[1].identifier, null, undefined, ''].forEach((ev) => {
        expect(isLabelEvent(labelEventIds, ev)).toEqual(false);
      });
      expect(isLabelEvent(labelEventIds)).toEqual(false);
    });
  });

  describe('eventToOption', () => {
    it('will return null if no valid object is passed in', () => {
      [{}, [], null, undefined].forEach((i) => {
        expect(eventToOption(i)).toEqual(null);
      });
    });

    it('will set the "value" property to the events identifier', () => {
      events.forEach((ev) => {
        const res = eventToOption(ev);
        expect(res.value).toEqual(ev.identifier);
      });
    });

    it('will set the "text" property to the events name', () => {
      events.forEach((ev) => {
        const res = eventToOption(ev);
        expect(res.text).toEqual(ev.name);
      });
    });
  });

  describe('getLabelEventsIdentifiers', () => {
    it('will return an array of identifiers for the label events', () => {
      const res = getLabelEventsIdentifiers(events);
      expect(res).toEqual(labelEventIds);
    });

    it('will return an empty array when there are no matches', () => {
      const ev = [{ _type: 'simple' }, { type: 'simple' }, { t: 'simple' }];
      expect(getLabelEventsIdentifiers(ev)).toEqual([]);
      expect(getLabelEventsIdentifiers([])).toEqual([]);
    });
  });

  describe('getAllowedEndEvents', () => {
    it('will return the relevant end events for a given start event identifier', () => {
      const se = events[0];
      expect(getAllowedEndEvents(events, se.identifier)).toEqual(se.allowedEndEvents);
    });

    it('will return an empty array if there are no end events available', () => {
      ['cool_issue_label_added', [], {}, null, undefined].forEach((ev) => {
        expect(getAllowedEndEvents(events, ev)).toEqual([]);
      });
    });
  });

  describe('eventsByIdentifier', () => {
    it('will return the events with an identifier in the provided array', () => {
      expect(eventsByIdentifier(events, labelEventIds)).toEqual(labelEvents);
    });

    it('will return an empty array if there are no matching events', () => {
      [['lol', 'bad'], [], {}, null, undefined].forEach((items) => {
        expect(eventsByIdentifier(events, items)).toEqual([]);
      });
      expect(eventsByIdentifier([], labelEvents)).toEqual([]);
    });
  });

  describe('flattenDurationChartData', () => {
    it('flattens the data as expected', () => {
      const flattenedData = flattenDurationChartData(transformedDurationData);

      expect(flattenedData).toStrictEqual(flattenedDurationData);
    });
  });

  describe('groupDurationsByDay', () => {
    it('returns a Map of the durations with the day as key', () => {
      const grouped = groupDurationsByDay(flattenDurationChartData(transformedDurationData));

      expect(grouped.size).toBe(2);

      expect(grouped.has('2019-01-01')).toBe(true);
      expect(grouped.get('2019-01-01')).toEqual([1134000, 2142000, 1234000]);

      expect(grouped.has('2019-01-02')).toBe(true);
      expect(grouped.get('2019-01-02')).toEqual([2321000, 3635000, 4321000]);
    });

    it('returns an empty Map given an empty array', () => {
      const grouped = groupDurationsByDay([]);

      expect(grouped.size).toBe(0);
    });
  });

  describe('cycleAnalyticsDurationChart', () => {
    let plottableData;

    const totalDays = getDayDifference(createdAfter, createdBefore);

    const nulledData = [{ data: [] }, { data: [] }];
    const zerodData = [
      { data: [{ average_duration_in_seconds: 0, date: '2019-01-01T00:00:00.000Z' }] },
      { data: [{ average_duration_in_seconds: 0, date: '2019-01-02T00:00:00.000Z' }] },
    ];

    const nulledPlottableData = [
      ['2019-01-01', null],
      ['2019-01-02', null],
    ];

    const zeroedPlottableData = [
      ['2019-01-01', 0],
      ['2019-01-02', 0],
    ];

    it.each`
      description                          | rawData                    | result
      ${'with positive average durations'} | ${transformedDurationData} | ${durationChartPlottableData}
      ${'with zeroes'}                     | ${zerodData}               | ${zeroedPlottableData}
      ${'with nulls'}                      | ${nulledData}              | ${nulledPlottableData}
    `('computes the plottable data for each day $description', ({ rawData, result }) => {
      plottableData = getDurationChartData(rawData, createdAfter, createdBefore);

      expect(plottableData).toEqual(expect.arrayContaining(result));
      expect(plottableData).toHaveLength(totalDays + 1);
    });
  });

  describe('formatDurationOverviewChartData', () => {
    it('formats the duration overview chart data as expected', () => {
      const durationData = [
        { average_duration_in_seconds: null, date: '2023-04-01' },
        { average_duration_in_seconds: 259200, date: '2023-04-02' },
        { average_duration_in_seconds: null, date: '2023-04-03' },
      ];

      const groupedDataByDay = new Map();

      groupedDataByDay.set('2023-04-01', [null, null, null]);
      groupedDataByDay.set('2023-04-02', [86400, 259200, null]);
      groupedDataByDay.set('2023-04-03', [432000, 172800, null]);

      const formattedDurationOverviewChartData = [
        ['2023-04-01', null],
        ['2023-04-02', 3],
        ['2023-04-03', 0],
      ];

      expect(formatDurationOverviewChartData(durationData, groupedDataByDay)).toStrictEqual(
        formattedDurationOverviewChartData,
      );
    });
  });

  describe('getDurationOverviewChartData', () => {
    const nulledData = [
      {
        name: 'Plan',
        data: [
          { average_duration_in_seconds: null, date: '2019-01-01T00:00:00.000Z' },
          { average_duration_in_seconds: null, date: '2019-01-02T00:00:00.000Z' },
        ],
      },
    ];

    const zerodData = [
      {
        name: 'Issue',
        data: [
          { average_duration_in_seconds: 0, date: '2019-01-01T00:00:00.000Z' },
          { average_duration_in_seconds: 0, date: '2019-01-02T00:00:00.000Z' },
        ],
      },
    ];

    const nullAndPositiveData = [
      {
        name: 'Issue',
        data: [
          { average_duration_in_seconds: null, date: '2019-01-01T00:00:00.000Z' },
          { average_duration_in_seconds: 259200, date: '2019-01-02T00:00:00.000Z' },
        ],
      },
      ...nulledData,
    ];

    const nulledPlottableData = [
      {
        name: 'Plan',
        data: [
          ['2019-01-01', null],
          ['2019-01-02', null],
        ],
      },
    ];

    const zeroedPlottableData = [
      {
        name: 'Issue',
        data: [
          ['2019-01-01', 0],
          ['2019-01-02', 0],
        ],
      },
    ];

    const nullAndPositivePlottableData = [
      {
        name: 'Issue',
        data: [
          ['2019-01-01', null],
          ['2019-01-02', 3],
        ],
      },
      {
        name: 'Plan',
        data: [
          ['2019-01-01', null],
          ['2019-01-02', 0],
        ],
      },
    ];

    it.each`
      description                                    | rawData                    | result
      ${'with positive average durations'}           | ${transformedDurationData} | ${durationOverviewChartPlottableData}
      ${'with zeroes'}                               | ${zerodData}               | ${zeroedPlottableData}
      ${'with nulls'}                                | ${nulledData}              | ${nulledPlottableData}
      ${'with positive average durations and nulls'} | ${nullAndPositiveData}     | ${nullAndPositivePlottableData}
    `('computes the plottable data for each stage $description', ({ rawData, result }) => {
      const plottableDurationOverviewData = getDurationOverviewChartData(rawData);

      expect(plottableDurationOverviewData).toEqual(expect.arrayContaining(result));
    });
  });

  describe('transformRawStages', () => {
    it('retains all the stage properties', () => {
      const transformed = transformRawStages([rawCustomStage]);
      expect(transformed).toMatchSnapshot();
    });

    it('converts object properties from snake_case to camelCase', () => {
      const [transformedCustomStage] = transformRawStages([rawCustomStage]);
      expect(transformedCustomStage).toMatchObject({
        endEventIdentifier: 'issue_first_added_to_board',
        startEventIdentifier: 'issue_first_mentioned_in_commit',
      });
    });

    it('sets the name to the value of the stage title if its not set', () => {
      const transformed = transformRawStages([issueStage, rawCustomStage]);
      transformed.forEach((t) => {
        expect(t.name.length > 0).toBe(true);
        expect(t.name).toEqual(t.title);
      });
    });
  });

  describe('prepareStageErrors', () => {
    const stages = [{ name: 'stage 1' }, { name: 'stage 2' }, { name: 'stage 3' }];
    const nameError = { name: "Can't be blank" };
    const stageErrors = { 1: nameError };

    it('returns an object for each stage', () => {
      const res = prepareStageErrors(stages, stageErrors);
      expect(res[0]).toEqual({});
      expect(res[1]).toEqual(nameError);
      expect(res[2]).toEqual({});
    });

    it('returns the same number of error objects as stages', () => {
      const res = prepareStageErrors(stages, stageErrors);
      expect(res).toHaveLength(stages.length);
    });

    it('returns an empty object for each stage if there are no errors', () => {
      const res = prepareStageErrors(stages, {});
      expect(res).toEqual([{}, {}, {}]);
    });
  });

  describe('flattenTaskByTypeSeries', () => {
    const dummySeries = Object.fromEntries([
      ['2019-01-16', 40],
      ['2019-01-14', 20],
      ['2019-01-12', 10],
      ['2019-01-15', 30],
    ]);

    let transformedDummySeries = [];

    beforeEach(() => {
      transformedDummySeries = flattenTaskByTypeSeries(dummySeries);
    });

    it('extracts the value from an array of datetime / value pairs', () => {
      expect(transformedDummySeries.every(isNumber)).toEqual(true);
      Object.values(dummySeries).forEach((v) => {
        expect(transformedDummySeries.includes(v)).toBe(true);
      });
    });

    it('sorts the items by the datetime parameter', () => {
      expect(transformedDummySeries).toEqual([10, 20, 30, 40]);
    });
  });

  describe('orderByDate', () => {
    it('sorts dates from the earliest to latest', () => {
      expect(['2019-01-14', '2019-01-12', '2019-01-16', '2019-01-15'].sort(orderByDate)).toEqual([
        '2019-01-12',
        '2019-01-14',
        '2019-01-15',
        '2019-01-16',
      ]);
    });
  });

  describe('getTasksByTypeData', () => {
    let transformed = {};
    const groupBy = getDatesInRange(createdAfter, createdBefore, toYmd);
    // only return the values, drop the date which is the first paramater
    const extractSeriesValues = ({ label: { title: name }, series }) => {
      return {
        name,
        data: series.map((kv) => kv[1]),
      };
    };

    const data = rawTasksByTypeData.map(extractSeriesValues);

    const labels = rawTasksByTypeData.map((d) => {
      const { label } = d;
      return label.title;
    });

    it('will return blank arrays if given no data', () => {
      [{ data: [], createdAfter, createdBefore }, [], {}].forEach((chartData) => {
        transformed = getTasksByTypeData(chartData);
        ['data', 'groupBy'].forEach((key) => {
          expect(transformed[key]).toEqual([]);
        });
      });
    });

    describe('with data', () => {
      beforeEach(() => {
        transformed = getTasksByTypeData({
          data: rawTasksByTypeData,
          createdAfter,
          createdBefore,
        });
      });

      it('will return an object with the properties needed for the chart', () => {
        ['data', 'groupBy'].forEach((key) => {
          expect(transformed).toHaveProperty(key);
        });
      });

      describe('groupBy', () => {
        it('returns the date groupBy as an array', () => {
          expect(transformed.groupBy).toEqual(groupBy);
        });

        it('the start date is the first element', () => {
          expect(transformed.groupBy[0]).toEqual(toYmd(createdAfter));
        });

        it('the end date is the last element', () => {
          expect(transformed.groupBy[transformed.groupBy.length - 1]).toEqual(toYmd(createdBefore));
        });
      });

      describe('data', () => {
        it('returns an array of data points', () => {
          expect(transformed.data).toEqual(data);
        });

        it('contains an array of data for each label', () => {
          expect(transformed.data).toHaveLength(labels.length);
        });

        it('contains a value for each day in the groupBy', () => {
          transformed.data.forEach((d) => {
            expect(d.data).toHaveLength(transformed.groupBy.length);
          });
        });
      });
    });
  });

  describe('toggleSelectedLabel', () => {
    const selectedLabels = [{ title: 'a' }, { title: 'b' }, { title: 'c' }];

    it('will return the array if theres no value given', () => {
      expect(toggleSelectedLabel({ selectedLabels })).toEqual(selectedLabels);
    });

    it('will add a label that does not exist', () => {
      expect(toggleSelectedLabel({ selectedLabels, value: { title: 'd' } })).toEqual([
        ...selectedLabels,
        { title: 'd' },
      ]);
    });

    it('filters by label title', () => {
      expect(toggleSelectedLabel({ selectedLabels, value: { title: 'b' } })).toEqual([
        { title: 'a' },
        { title: 'c' },
      ]);
    });
  });

  describe('formatMedianValuesWithOverview', () => {
    const calculatedMedians = formatMedianValuesWithOverview(rawStageMedians);

    it('returns an object with each stage and their median formatted for display', () => {
      rawStageMedians.forEach(({ id, value }) => {
        expect(calculatedMedians).toMatchObject({ [id]: medianTimeToParsedSeconds(value) });
      });
    });

    it('calculates a median for the overview stage', () => {
      expect(calculatedMedians).toMatchObject({ [OVERVIEW_STAGE_ID]: '3w' });
    });
  });

  describe('generateFilterTextDescription', () => {
    it.each`
      selectedLabelsCount | selectedProjectsCount | text
      ${2}                | ${2}                  | ${"Shows Merge Requests and 2 labels for group 'Earth special forces' and 2 projects from Dec 11, 2019 to Jan 10, 2020"}
      ${2}                | ${1}                  | ${"Shows Merge Requests and 2 labels for group 'Earth special forces' and 1 project from Dec 11, 2019 to Jan 10, 2020"}
      ${2}                | ${0}                  | ${"Shows Merge Requests and 2 labels for group 'Earth special forces' from Dec 11, 2019 to Jan 10, 2020"}
      ${1}                | ${2}                  | ${"Shows Merge Requests and 1 label for group 'Earth special forces' and 2 projects from Dec 11, 2019 to Jan 10, 2020"}
      ${1}                | ${1}                  | ${"Shows Merge Requests and 1 label for group 'Earth special forces' and 1 project from Dec 11, 2019 to Jan 10, 2020"}
      ${1}                | ${0}                  | ${"Shows Merge Requests and 1 label for group 'Earth special forces' from Dec 11, 2019 to Jan 10, 2020"}
      ${0}                | ${2}                  | ${"Shows Merge Requests for group 'Earth special forces' and 2 projects from Dec 11, 2019 to Jan 10, 2020"}
      ${0}                | ${1}                  | ${"Shows Merge Requests for group 'Earth special forces' and 1 project from Dec 11, 2019 to Jan 10, 2020"}
      ${0}                | ${0}                  | ${"Shows Merge Requests for group 'Earth special forces' from Dec 11, 2019 to Jan 10, 2020"}
    `(
      'with labels=$selectedLabelsCount and projects=$selectedProjectsCount returns "$text"',
      ({ selectedProjectsCount, selectedLabelsCount, text }) => {
        const str = generateFilterTextDescription({
          selectedSubjectFilterText:
            TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS[TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST],
          groupName: 'Earth special forces',
          createdAfter: 'Dec 11, 2019',
          createdBefore: 'Jan 10, 2020',
          selectedProjectsCount,
          selectedLabelsCount,
        });
        expect(str).toBe(text);
      },
    );
  });
});
