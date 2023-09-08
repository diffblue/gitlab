/**
 * This util method takes the global page filters and transforms parameters which
 * are not standardized between the internal issue analytics api and the public
 * issues api.
 *
 * @param {Object} filters the global filters used to fetch issues data
 *
 * @returns {Object} the transformed filters for the public api
 */
export const transformFilters = ({
  assignee_username: assigneeUsernames = null,
  author_username: authorUsername = null,
  label_name: labelNames = null,
  milestone_title: milestoneTitle = null,
  months_back: monthsBack = null,
}) => ({
  assigneeUsernames,
  authorUsername,
  labelNames,
  milestoneTitle,
  monthsBack,
});
