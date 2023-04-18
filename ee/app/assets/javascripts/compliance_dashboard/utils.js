import { convertToGraphQLIds } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { formatDate, getDateInPast, pikadayToString } from '~/lib/utils/datetime_utility';
import { ISO_SHORT_FORMAT } from '~/vue_shared/constants';
import { queryToObject } from '~/lib/utils/url_utility';
import {
  FRAMEWORKS_FILTER_TYPE_FRAMEWORK,
  FRAMEWORKS_FILTER_TYPE_PROJECT,
} from 'ee/compliance_dashboard/constants';
import { CURRENT_DATE } from '../audit_events/constants';

export const convertProjectIdsToGraphQl = (projectIds) =>
  convertToGraphQLIds(
    TYPENAME_PROJECT,
    projectIds.filter((id) => Boolean(id)),
  );

export const parseViolationsQueryFilter = ({
  mergedBefore,
  mergedAfter,
  projectIds,
  targetBranch,
}) => ({
  projectIds: projectIds ? convertProjectIdsToGraphQl(projectIds) : [],
  mergedBefore: formatDate(mergedBefore, ISO_SHORT_FORMAT, true),
  mergedAfter: formatDate(mergedAfter, ISO_SHORT_FORMAT, true),
  targetBranch,
});

export const buildDefaultViolationsFilterParams = (queryString) => ({
  mergedAfter: pikadayToString(getDateInPast(CURRENT_DATE, 30)),
  mergedBefore: pikadayToString(CURRENT_DATE),
  ...queryToObject(queryString, { gatherArrays: true }),
});

export function mapFiltersToUrlParams(filters) {
  const urlParams = {};

  const projectSearch = filters.find((filter) => filter.type === FRAMEWORKS_FILTER_TYPE_PROJECT);
  urlParams.project = projectSearch?.value?.data ?? undefined;

  const complianceFilter = filters.find(
    (filter) => filter.type === FRAMEWORKS_FILTER_TYPE_FRAMEWORK,
  );
  urlParams.framework = complianceFilter?.value?.data ?? undefined;
  urlParams.frameworkExclude = complianceFilter?.value?.operator === '!=' ? true : undefined;

  return urlParams;
}

export function mapQueryToFilters(queryParams) {
  const { project, framework, frameworkExclude } = queryParams;
  const filters = [];

  if (project) {
    filters.push({
      type: FRAMEWORKS_FILTER_TYPE_PROJECT,
      value: { data: project, operator: 'matches' },
    });
  }

  if (framework) {
    filters.push({
      type: FRAMEWORKS_FILTER_TYPE_FRAMEWORK,
      value: { data: framework, operator: frameworkExclude ? '!=' : '=' },
    });
  }

  return filters;
}

export const checkFilterForChange = ({ currentFilters = {}, newFilters = {} }) => {
  const filterKeys = ['project', 'framework', 'frameworkExclude'];

  return filterKeys.some((key) => currentFilters[key] !== newFilters[key]);
};
