import { sortBy } from 'lodash';
import {
  parsePikadayDate,
  pikadayToString,
  nDaysAfter,
  differenceInMilliseconds,
} from '~/lib/utils/datetime_utility';
import { MAX_DAYS_PER_REQUEST } from './constants';

const sortData = (data) => sortBy(data, (item) => item[1]).reverse();

export const formatChartData = (data, labels) =>
  sortData(data.map((val, index) => [labels[index], val]));

/**
 * A util function which extracts push counts and user name from raw contributions data
 *
 * @param { Array } contributions the raw contributions data
 *
 * @return { Array } an array containing filtered and formatted push counts data
 */
export const filterPushes = (contributions) => {
  return contributions
    .filter(({ repoPushed }) => repoPushed > 0)
    .map(({ repoPushed: count, user: { name: user } }) => ({ count, user }));
};

/**
 * A util function which extracts merge request counts and user name from raw contributions data
 *
 * @param { Array } contributions the raw contributions data
 *
 * @return { Array } an array containing filtered and formatted merge request counts data
 */
export const filterMergeRequests = (contributions) => {
  return contributions
    .filter(
      ({
        mergeRequestsClosed: closed,
        mergeRequestsCreated: created,
        mergeRequestsMerged: merged,
      }) => closed + created + merged > 0,
    )
    .map(
      ({
        mergeRequestsClosed: closed,
        mergeRequestsCreated: created,
        mergeRequestsMerged: merged,
        user: { name: user },
      }) => ({ closed, created, merged, user }),
    );
};

/**
 * A util function which extracts issue counts and user name from raw contributions data
 *
 * @param { Array } contributions the raw contributions data
 *
 * @return { Array } an array containing filtered and formatted issue counts data
 */
export const filterIssues = (contributions) => {
  return contributions
    .filter(({ issuesClosed: closed, issuesCreated: created }) => closed + created > 0)
    .map(({ issuesClosed: closed, issuesCreated: created, user: { name: user } }) => ({
      closed,
      created,
      user,
    }));
};

/**
 * To prevent excessively large queries, we limit the date range of the
 * requests to fetch contributions.
 *
 * @param { String } startDate in the format YYYY-MM-DD
 * @param { String } endDate in the format YYYY-MM-DD
 *
 * @return { Object }
 * @return { Object.endDate } The restricted end date in the format YYYY-MM-DD
 * @return { Object.nextStartDate } The start date to be used for the next request
 */
export const restrictRequestEndDate = (startDate, maxEndDate) => {
  const endDate = nDaysAfter(parsePikadayDate(startDate), MAX_DAYS_PER_REQUEST);

  const atMaxEndDate = differenceInMilliseconds(parsePikadayDate(maxEndDate), endDate) >= 0;
  if (atMaxEndDate) {
    return { endDate: maxEndDate, nextStartDate: null };
  }

  return {
    endDate: pikadayToString(endDate),
    nextStartDate: pikadayToString(nDaysAfter(endDate, 1)),
  };
};

/**
 * Sums the data of two contributions for the same user.
 * If B has no data, A is returned.
 *
 * @param { Object } a
 * @param { Object } b
 *
 * @return { Object } The combined contribution data
 */
const mergeContribution = (a, b) =>
  b
    ? {
        user: a.user,
        issuesClosed: a.issuesClosed + b.issuesClosed,
        issuesCreated: a.issuesCreated + b.issuesCreated,
        mergeRequestsApproved: a.mergeRequestsApproved + b.mergeRequestsApproved,
        mergeRequestsClosed: a.mergeRequestsClosed + b.mergeRequestsClosed,
        mergeRequestsCreated: a.mergeRequestsCreated + b.mergeRequestsCreated,
        mergeRequestsMerged: a.mergeRequestsMerged + b.mergeRequestsMerged,
        repoPushed: a.repoPushed + b.repoPushed,
        totalEvents: a.totalEvents + b.totalEvents,
      }
    : a;

/**
 * Merges two contributions arrays together into a single array.
 * Metrics for duplicate entries are added together in the final result.
 *
 * @param { Array } a
 * @param { Array } b
 *
 * @return { Array } The combined array
 */
export const mergeContributions = (a, b) => {
  // Convert to object so we can easily find duplicate user IDs
  const hash = a.reduce((acc, c) => ({ ...acc, [c.user.id]: c }), {});
  const merged = b.reduce(
    (acc, c) => ({ ...acc, [c.user.id]: mergeContribution(c, hash[c.user.id]) }),
    hash,
  );
  return Object.values(merged);
};
