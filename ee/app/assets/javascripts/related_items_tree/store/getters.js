import { TYPE_EPIC } from '~/issues/constants';
import { PathIdSeparator } from '~/related_issues/constants';
import { processIssueTypeIssueSources } from '../utils/epic_utils';

export const autoCompleteSources = () => gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources;

export const directChildren = (state) => state.children[state.parentItem.reference] || [];

export const anyParentHasChildren = (state, getters) =>
  getters.directChildren.some((item) => item.hasChildren || item.hasIssues);

export const itemAutoCompleteSources = (state, getters) => {
  if (getters.isEpic) {
    return state.autoCompleteEpics ? getters.autoCompleteSources : {};
  }

  if (state.issuesEndpoint.includes('epics')) {
    return {
      ...getters.autoCompleteSources,
      issues: processIssueTypeIssueSources(['issue'], getters.autoCompleteSources),
    };
  }

  return state.autoCompleteIssues ? getters.autoCompleteSources : {};
};

export const itemPathIdSeparator = (state, getters) =>
  getters.isEpic ? PathIdSeparator.Epic : PathIdSeparator.Issue;

export const isEpic = (state) => state.issuableType === TYPE_EPIC;
