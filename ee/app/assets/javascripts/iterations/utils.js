import { formatDate } from '~/lib/utils/datetime_utility';

const PERIOD_DATE_FORMAT = 'mmm d, yyyy';

/**
 * The arguments are two date strings in formatted in ISO 8601 (YYYY-MM-DD)
 *
 * @returns {string} ex. "Oct 1, 2021 - Oct 10, 2021"
 */
export function getIterationPeriod({ startDate, dueDate }) {
  const start = formatDate(startDate, PERIOD_DATE_FORMAT, true);
  const due = formatDate(dueDate, PERIOD_DATE_FORMAT, true);
  return `${start} - ${due}`;
}
