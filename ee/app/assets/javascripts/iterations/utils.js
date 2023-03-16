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

/**
 * Group a list of iterations by cadence.
 *
 * @param iterations A list of iterations
 * @return {Array} A list of cadences
 */
export function groupByIterationCadences(iterations) {
  const cadences = [];
  iterations.forEach((iteration) => {
    if (!iteration.iterationCadence) {
      return;
    }
    const { title, id } = iteration.iterationCadence;
    const cadenceIteration = {
      id: iteration.id,
      title: iteration.title,
      period: getIterationPeriod(iteration),
    };
    const cadence = cadences.find((c) => c.title === title);
    if (cadence) {
      cadence.iterations.push(cadenceIteration);
    } else {
      cadences.push({ title, iterations: [cadenceIteration], id });
    }
  });
  return cadences;
}

export function groupOptionsByIterationCadences(iterations) {
  const cadences = [];
  iterations.forEach((iteration) => {
    if (!iteration.iterationCadence) {
      return;
    }
    const { title } = iteration.iterationCadence;
    const cadenceIteration = {
      value: iteration.id,
      title: iteration.title,
      text: getIterationPeriod(iteration),
    };
    const cadence = cadences.find((c) => c.text === title);
    if (cadence) {
      cadence.options.push(cadenceIteration);
    } else {
      cadences.push({ text: title, options: [cadenceIteration] });
    }
  });
  return cadences;
}
