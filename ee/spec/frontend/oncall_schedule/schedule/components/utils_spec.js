import { getTimeframeForWeeksView } from 'ee/oncall_schedules/components/schedule/utils';

describe('getTimeframeForWeeksView', () => {
  const mockTimeframeInitialDate = new Date(2018, 0, 1);
  const timeframe = getTimeframeForWeeksView(mockTimeframeInitialDate);

  it('returns timeframe with total of 2 weeks', () => {
    expect(timeframe).toHaveLength(2);
  });

  it('first timeframe item refers to the start date', () => {
    const timeframeItem = timeframe[0];
    const expectedMonth = {
      year: 2018,
      month: 0,
      date: 1,
    };

    expect(timeframeItem.getFullYear()).toBe(expectedMonth.year);
    expect(timeframeItem.getMonth()).toBe(expectedMonth.month);
    expect(timeframeItem.getDate()).toBe(expectedMonth.date);
  });

  it('second timeframe item refers to first date of the next week week', () => {
    const timeframeItem = timeframe[timeframe.length - 1];
    const expectedMonth = {
      year: 2018,
      month: 0,
      date: 8,
    };

    expect(timeframeItem.getFullYear()).toBe(expectedMonth.year);
    expect(timeframeItem.getMonth()).toBe(expectedMonth.month);
    expect(timeframeItem.getDate()).toBe(expectedMonth.date);
  });
});
