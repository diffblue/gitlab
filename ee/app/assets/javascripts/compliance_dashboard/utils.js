import { convertToGraphQLIds } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { formatDate, getDateInPast, pikadayToString } from '~/lib/utils/datetime_utility';
import { ISO_SHORT_FORMAT } from '~/vue_shared/constants';
import { queryToObject } from '~/lib/utils/url_utility';
import { TAB_FRAMEWORKS } from 'ee/compliance_dashboard/constants';
import { CURRENT_DATE } from '../audit_events/constants';

export const convertProjectIdsToGraphQl = (projectIds) =>
  convertToGraphQLIds(
    TYPENAME_PROJECT,
    projectIds.filter((id) => Boolean(id)),
  );

export const parseViolationsQueryFilter = ({ mergedBefore, mergedAfter, projectIds }) => ({
  projectIds: projectIds ? convertProjectIdsToGraphQl(projectIds) : [],
  mergedBefore: formatDate(mergedBefore, ISO_SHORT_FORMAT, true),
  mergedAfter: formatDate(mergedAfter, ISO_SHORT_FORMAT, true),
});

export const buildDefaultViolationsFilterParams = (queryString) => ({
  mergedAfter: pikadayToString(getDateInPast(CURRENT_DATE, 30)),
  mergedBefore: pikadayToString(CURRENT_DATE),
  ...queryToObject(queryString, { gatherArrays: true }),
});

export const buildDefaultFrameworkFilterParams = (queryString) => {
  const { tab } = queryToObject(queryString, { gatherArrays: true });

  return {
    tab: tab || TAB_FRAMEWORKS,
  };
};
