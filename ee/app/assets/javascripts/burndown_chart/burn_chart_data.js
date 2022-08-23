import dateFormat from '~/lib/dateformat';

export default class BurnChartData {
  constructor(events, startDate, dueDate) {
    this.dateFormatMask = 'yyyy-mm-dd';
    this.startDate = startDate;
    this.dueDate = dueDate;

    // determine when to stop burndown chart
    const today = dateFormat(Date.now(), this.dateFormatMask);
    this.endDate = today < this.dueDate ? today : this.dueDate;

    // Make sure we get the burndown chart local start and end dates! new Date()
    // and dateFormat() both convert the date at midnight UTC to the browser's
    // timezone, leading to incorrect chart start and end points. Using
    // new Date('YYYY-MM-DDTHH:MM:SS') gets the user's local date at midnight.

    this.localStartDate = new Date(`${this.startDate}T00:00:00`);
    this.localEndDate = new Date(`${this.endDate}T00:00:00`);

    this.events = this.processRawEvents(events);
  }

  generateBurnupTimeseries({ milestoneId } = {}) {
    const chartData = [];

    let openIssuesCount = 0;
    let carriedIssuesCount = 0;

    for (
      let date = this.localStartDate;
      date <= this.localEndDate;
      date.setDate(date.getDate() + 1)
    ) {
      const dateString = dateFormat(date, this.dateFormatMask);

      const openedIssuesToday = this.filterAndSummarizeBurndownEvents(
        (event) =>
          event.created_at === dateString &&
          event.event_type === 'milestone' &&
          event.milestone_id === milestoneId &&
          event.action === 'add',
      );

      const closedIssuesToday = this.filterAndSummarizeBurndownEvents(
        (event) =>
          event.created_at === dateString &&
          event.event_type === 'milestone' &&
          ((event.action === 'remove' && event.milestone_id === milestoneId) ||
            (event.action === 'add' && event.milestone_id !== milestoneId)),
      );

      openIssuesCount += openedIssuesToday.count - closedIssuesToday.count;

      if (openIssuesCount + carriedIssuesCount < 0) {
        carriedIssuesCount += openIssuesCount;

        openIssuesCount = 0;
      } else {
        openIssuesCount += carriedIssuesCount;

        carriedIssuesCount = 0;
      }

      chartData.push([dateString, openIssuesCount]);
    }

    return {
      burnupScope: chartData,
    };
  }

  generateBurndownTimeseries() {
    let openIssuesCount = 0;
    let openIssuesWeight = 0;

    let carriedIssuesCount = 0;
    let carriedIssuesWeight = 0;

    const chartData = [];

    for (
      let date = this.localStartDate;
      date <= this.localEndDate;
      date.setDate(date.getDate() + 1)
    ) {
      const dateString = dateFormat(date, this.dateFormatMask);

      const openedIssuesToday = this.filterAndSummarizeBurndownEvents(
        (event) =>
          event.created_at === dateString &&
          (event.action === 'created' || event.action === 'reopened'),
      );

      const closedIssuesToday = this.filterAndSummarizeBurndownEvents(
        (event) => event.created_at === dateString && event.action === 'closed',
      );

      openIssuesCount += openedIssuesToday.count - closedIssuesToday.count;
      openIssuesWeight += openedIssuesToday.weight - closedIssuesToday.weight;

      // Due to timezone differences or unforeseen bugs/errors in the source or
      // processed data, it is possible that we end up with a negative issue or
      // weight count on an given date. To mitigate this, we reset the current
      // date's counters to 0 and carry forward the negative count to a future
      // date until the total is positive again.
      if (openIssuesCount + carriedIssuesCount < 0 || openIssuesWeight + carriedIssuesWeight < 0) {
        carriedIssuesCount += openIssuesCount;
        carriedIssuesWeight += openIssuesWeight;

        openIssuesCount = 0;
        openIssuesWeight = 0;
      } else {
        openIssuesCount += carriedIssuesCount;
        openIssuesWeight += carriedIssuesWeight;

        carriedIssuesCount = 0;
        carriedIssuesWeight = 0;
      }

      chartData.push([dateString, openIssuesCount, openIssuesWeight]);
    }

    return chartData;
  }

  // Process raw milestone events:
  // 1. Set event creation date to milestone start date if created before milestone start
  // 2. Convert event creation datetime to date in local timezone
  processRawEvents(events) {
    return events.map((event) => ({
      ...event,
      created_at:
        dateFormat(event.created_at, this.dateFormatMask) < this.startDate
          ? this.startDate
          : dateFormat(event.created_at, this.dateFormatMask),
    }));
  }

  filterAndSummarizeBurndownEvents(filter) {
    const issues = this.events.filter(filter);

    return {
      count: issues.length,
      weight: issues.reduce((total, issue) => total + issue.weight, 0),
    };
  }
}
