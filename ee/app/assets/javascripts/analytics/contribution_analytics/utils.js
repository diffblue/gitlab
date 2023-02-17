import { sortBy } from 'lodash';

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
