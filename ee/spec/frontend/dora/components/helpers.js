import dateFormat from '~/lib/dateformat';

export const formattedDate = (date) => dateFormat(date, 'mmm d', true);

export const forecastDataToChartDate = (data, forecast) =>
  [...data.slice(-1), ...forecast].map(({ date, value }) => [formattedDate(date), value]);
