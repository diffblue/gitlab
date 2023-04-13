import { dateFormats } from '~/analytics/shared/constants';
import { OVERVIEW_STAGE_ID } from '~/analytics/cycle_analytics/constants';
import { filterStagesByHiddenStatus } from '~/analytics/cycle_analytics/utils';
import {
  pathNavigationData as basePathNavigationData,
  paginationParams as basePaginationParams,
} from '~/analytics/cycle_analytics/store/getters';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import dateFormat from '~/lib/dateformat';
import { HTTP_STATUS_FORBIDDEN } from '~/lib/utils/http_status';
import { filterToQueryObject } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { DEFAULT_VALUE_STREAM_ID, OVERVIEW_STAGE_CONFIG } from '../constants';
import { NAMESPACE_TYPES } from '../../../vue_shared/components/runner_tags_dropdown/constants';

export const isProjectNamespace = ({ namespace }) =>
  Boolean(namespace.type?.toLowerCase() === NAMESPACE_TYPES.PROJECT);

export const namespacePath = ({ namespace }) => namespace?.fullPath || null;

export const hasNoAccessError = (state) => state.errorCode === HTTP_STATUS_FORBIDDEN;

export const hasValueStreams = ({ valueStreams }) => Boolean(valueStreams?.length);

export const currentValueStreamId = ({ selectedValueStream }) =>
  selectedValueStream?.id || DEFAULT_VALUE_STREAM_ID;

export const selectedProjectIds = ({ selectedProjects }) =>
  selectedProjects?.map(({ id }) => getIdFromGraphQLId(id)) || [];

export const selectedProjectFullPaths = ({ selectedProjects }) =>
  selectedProjects?.map(({ fullPath }) => fullPath) || [];

export const cycleAnalyticsRequestParams = (state, getters) => {
  const {
    createdAfter = null,
    createdBefore = null,
    filters: {
      authors: { selected: selectedAuthor },
      milestones: { selected: selectedMilestone },
      assignees: { selectedList: selectedAssigneeList },
      labels: { selectedList: selectedLabelList },
    },
  } = state;

  const filterBarQuery = filterToQueryObject({
    milestone_title: selectedMilestone,
    author_username: selectedAuthor,
    label_name: selectedLabelList,
    assignee_username: selectedAssigneeList,
  });

  return {
    project_ids: getters.selectedProjectIds?.length ? getters.selectedProjectIds : null,
    created_after: createdAfter ? dateFormat(createdAfter, dateFormats.isoDate) : null,
    created_before: createdBefore ? dateFormat(createdBefore, dateFormats.isoDate) : null,
    ...filterBarQuery,
  };
};

export const paginationParams = basePaginationParams;

export const hiddenStages = ({ stages }) => filterStagesByHiddenStatus(stages);
export const activeStages = ({ stages }) => filterStagesByHiddenStatus(stages, false);

export const customStageFormActive = ({ isCreatingCustomStage, isEditingCustomStage }) =>
  Boolean(isCreatingCustomStage || isEditingCustomStage);

export const isOverviewStageSelected = ({ selectedStage }) =>
  selectedStage?.id === OVERVIEW_STAGE_ID;

/**
 * Until there are controls in place to edit stages outside of the stage table,
 * the path navigation component will only display active stages.
 *
 * https://gitlab.com/gitlab-org/gitlab/-/issues/216227
 */
export const pathNavigationData = ({ stages, medians, stageCounts, selectedStage }) =>
  basePathNavigationData({
    stages: [OVERVIEW_STAGE_CONFIG, ...stages],
    medians,
    stageCounts,
    selectedStage,
  });

export const selectedStageCount = ({ selectedStage, stageCounts }) =>
  stageCounts[selectedStage.id] || null;
