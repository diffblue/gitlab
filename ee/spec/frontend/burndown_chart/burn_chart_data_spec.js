import timezoneMock from 'timezone-mock';
import BurndownChartData from 'ee/burndown_chart/burn_chart_data';
import { useFakeDate } from 'helpers/fake_date';
import dateFormat from '~/lib/dateformat';

describe('BurndownChartData', () => {
  const startDate = '2017-03-01';
  const dueDate = '2017-03-03';

  const issueStateEvents = [
    { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
    { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
    { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'reopened' },
  ];

  describe('generateBurndownTimeseries', () => {
    let burndownChartData;

    beforeEach(() => {
      burndownChartData = new BurndownChartData(issueStateEvents, startDate, dueDate);
    });

    it('generates an array of arrays with date, issue count and weight', () => {
      expect(burndownChartData.generateBurndownTimeseries()).toEqual([
        ['2017-03-01', 2, 4],
        ['2017-03-02', 1, 2],
        ['2017-03-03', 3, 6],
      ]);
    });

    describe('when viewing in a timezone in the west', () => {
      beforeAll(() => {
        timezoneMock.register('US/Pacific');
      });

      afterAll(() => {
        timezoneMock.unregister();
      });

      it('has the right start and end dates', () => {
        expect(burndownChartData.generateBurndownTimeseries()).toEqual([
          ['2017-03-01', 1, 2],
          ['2017-03-02', 3, 6],
          ['2017-03-03', 3, 6],
        ]);
      });
    });

    describe('when issues are created before start date', () => {
      beforeAll(() => {
        issueStateEvents.push({
          created_at: '2017-02-28T00:00:00.000Z',
          weight: 2,
          action: 'created',
        });
      });

      it('generates an array of arrays with date, issue count and weight', () => {
        expect(burndownChartData.generateBurndownTimeseries()).toEqual([
          ['2017-03-01', 3, 6],
          ['2017-03-02', 2, 4],
          ['2017-03-03', 4, 8],
        ]);
      });
    });

    describe('when viewing before due date', () => {
      useFakeDate(2017, 2, 2);

      it('counts until today if milestone due date > date today', () => {
        const chartData = burndownChartData.generateBurndownTimeseries();

        expect(dateFormat(Date.now(), 'yyyy-mm-dd')).toEqual('2017-03-02');
        expect(chartData[chartData.length - 1][0]).toEqual('2017-03-02');
      });
    });

    describe('when days in milestone have negative counts', () => {
      describe('and the first two days have a negative count', () => {
        beforeAll(() => {
          issueStateEvents.length = 0;
          issueStateEvents.push(
            { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
          );
        });

        it('generates an array where the first two days counts are zero', () => {
          expect(burndownChartData.generateBurndownTimeseries()).toEqual([
            ['2017-03-01', 0, 0],
            ['2017-03-02', 0, 0],
            ['2017-03-03', 1, 2],
          ]);
        });
      });

      describe('and the middle day has a negative count', () => {
        // This scenario is unlikely to occur as this implies there are more
        // closed issues than total issues, but we account for it anyway as a
        // potential edge case.

        beforeAll(() => {
          issueStateEvents.length = 0;
          issueStateEvents.push(
            { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
          );
        });

        it('generates an array where the middle day count is zero', () => {
          expect(burndownChartData.generateBurndownTimeseries()).toEqual([
            ['2017-03-01', 1, 2],
            ['2017-03-02', 0, 0],
            ['2017-03-03', 1, 2],
          ]);
        });
      });

      describe('and the last day has a negative count', () => {
        // This scenario is unlikely to occur as this implies there are more
        // closed issues than total issues, but we account for it anyway as a
        // potential edge case.

        beforeAll(() => {
          issueStateEvents.length = 0;
          issueStateEvents.push(
            { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'closed' },
          );
        });

        it('generates an array where all counts are zero', () => {
          expect(burndownChartData.generateBurndownTimeseries()).toEqual([
            ['2017-03-01', 0, 0],
            ['2017-03-02', 0, 0],
            ['2017-03-03', 0, 0],
          ]);
        });
      });
    });
  });

  describe('generateBurnupTimeseries', () => {
    const milestoneId = 400;
    const milestoneEvents = [
      // day 1: add two issues to the milestone
      {
        action: 'add',
        created_at: '2017-03-01T00:00:00.000Z',
        event_type: 'milestone',
        issue_id: 1,
        milestone_id: milestoneId,
        weight: null,
      },
      {
        action: 'add',
        created_at: '2017-03-01T00:00:00.000Z',
        event_type: 'milestone',
        issue_id: 2,
        milestone_id: milestoneId,
        weight: null,
      },
      // day 2: remove both issues we added yesterday, add a different issue
      {
        action: 'remove',
        created_at: '2017-03-02T00:00:00.000Z',
        event_type: 'milestone',
        issue_id: 2,
        milestone_id: milestoneId,
        weight: null,
      },
      {
        action: 'add',
        created_at: '2017-03-02T00:00:00.000Z',
        event_type: 'milestone',
        issue_id: 3,
        milestone_id: milestoneId,
        weight: null,
      },
      {
        action: 'remove',
        created_at: '2017-03-02T00:00:00.000Z',
        event_type: 'milestone',
        issue_id: 1,
        milestone_id: milestoneId,
        weight: null,
      },
      // day 3: remove yesterday's issue, also remove an issue that didn't have an `add` event
      {
        action: 'remove',
        created_at: '2017-03-03T00:00:00.000Z',
        event_type: 'milestone',
        issue_id: 2,
        milestone_id: milestoneId,
        weight: null,
      },
      {
        action: 'remove',
        created_at: '2017-03-03T00:00:00.000Z',
        event_type: 'milestone',
        issue_id: 4,
        milestone_id: milestoneId,
        weight: null,
      },
    ];

    const burndownChartData = (events = milestoneEvents) => {
      return new BurndownChartData(events, startDate, dueDate);
    };

    it('generates an array of arrays with date and issue count', () => {
      const { burnupScope } = burndownChartData().generateBurnupTimeseries({ milestoneId });

      expect(burnupScope).toEqual([
        ['2017-03-01', 2],
        ['2017-03-02', 1],
        ['2017-03-03', 0],
      ]);
    });

    it('starts from 0', () => {
      const { burnupScope } = burndownChartData([]).generateBurnupTimeseries({
        milestoneId,
      });

      expect(burnupScope[0]).toEqual(['2017-03-01', 0], ['2017-03-01', 0], ['2017-03-01', 0]);
    });

    it('does not go below zero with extra remove events', () => {
      const { burnupScope } = burndownChartData([
        {
          action: 'remove',
          created_at: '2017-03-02T00:00:00.000Z',
          event_type: 'milestone',
          issue_id: 2,
          milestone_id: milestoneId,
          weight: null,
        },
        {
          action: 'remove',
          created_at: '2017-03-02T00:00:00.000Z',
          event_type: 'milestone',
          issue_id: 1,
          milestone_id: milestoneId,
          weight: null,
        },
      ]).generateBurnupTimeseries({
        milestoneId,
      });

      expect(burnupScope).toEqual([
        ['2017-03-01', 0],
        ['2017-03-02', 0],
        ['2017-03-03', 0],
      ]);
    });

    it('ignores removed from other milestones', () => {
      const differentMilestoneId = 600;
      const events = [
        {
          created_at: '2017-03-01T00:00:00.000Z',
          action: 'add',
          event_type: 'milestone',
          milestone_id: milestoneId,
          issue_id: 1,
        },
        {
          created_at: '2017-03-01T00:00:00.000Z',
          action: 'remove',
          event_type: 'milestone',
          milestone_id: differentMilestoneId,
          issue_id: 1,
        },
      ];

      const { burnupScope } = burndownChartData(events).generateBurnupTimeseries({ milestoneId });

      expect(burnupScope).toEqual([
        ['2017-03-01', 1],
        ['2017-03-02', 1],
        ['2017-03-03', 1],
      ]);
    });

    it('only adds milestone event_type', () => {
      const events = [
        {
          created_at: '2017-03-01T00:00:00.000Z',
          action: 'add',
          event_type: 'weight',
          milestone_id: milestoneId,
          issue_id: 1,
          weight: 2,
        },
        {
          created_at: '2017-03-02T00:00:00.000Z',
          action: 'add',
          event_type: 'milestone',
          milestone_id: milestoneId,
          issue_id: 1,
          weight: null,
        },
      ];

      const { burnupScope } = burndownChartData(events).generateBurnupTimeseries({ milestoneId });

      expect(burnupScope).toEqual([
        ['2017-03-01', 0],
        ['2017-03-02', 1],
        ['2017-03-03', 1],
      ]);
    });

    it('only removes milestone event_type', () => {
      const events = [
        {
          created_at: '2017-03-01T00:00:00.000Z',
          action: 'add',
          event_type: 'milestone',
          milestone_id: milestoneId,
          issue_id: 1,
        },
        {
          created_at: '2017-03-02T00:00:00.000Z',
          action: 'remove',
          event_type: 'weight',
          milestone_id: milestoneId,
          issue_id: 1,
          weight: 2,
        },
        {
          created_at: '2017-03-03T00:00:00.000Z',
          action: 'remove',
          event_type: 'milestone',
          milestone_id: milestoneId,
          issue_id: 1,
        },
      ];

      const { burnupScope } = burndownChartData(events).generateBurnupTimeseries({ milestoneId });

      expect(burnupScope).toEqual([
        ['2017-03-01', 1],
        ['2017-03-02', 1],
        ['2017-03-03', 0],
      ]);
    });
  });
});
