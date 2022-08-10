import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_DATA](
    state,
    {
      groupNamespace = null,
      projectPath = null,
      authorUsername = null,
      labelName = [],
      milestoneTitle = null,
      notAuthorUsername = null,
      notLabelName = [],
      notMilestoneTitle = null,
      mergedAfter,
      mergedBefore,
      minDate,
    },
  ) {
    state.groupNamespace = groupNamespace;
    state.projectPath = projectPath;
    state.authorUsername = authorUsername;
    state.labelName = labelName;
    state.milestoneTitle = milestoneTitle;
    state.notAuthorUsername = notAuthorUsername;
    state.notLabelName = notLabelName;
    state.notMilestoneTitle = notMilestoneTitle;
    state.startDate = mergedAfter;
    state.endDate = mergedBefore;
    state.minDate = minDate;
  },
  [types.SET_GROUP_NAMESPACE](state, groupNamespace) {
    state.groupNamespace = groupNamespace;
    state.projectPath = null;
    state.authorUsername = null;
    state.labelName = [];
    state.milestoneTitle = null;
    state.notAuthorUsername = null;
    state.notLabelName = [];
    state.notMilestoneTitle = null;
  },
  [types.SET_PROJECT_PATH](state, projectPath) {
    state.projectPath = projectPath;
    state.authorUsername = null;
    state.labelName = [];
    state.milestoneTitle = null;
    state.notAuthorUsername = null;
    state.notLabelName = [];
    state.notMilestoneTitle = null;
  },
  [types.SET_FILTERS](
    state,
    {
      authorUsername,
      labelName,
      milestoneTitle,
      notAuthorUsername,
      notLabelName,
      notMilestoneTitle,
    },
  ) {
    state.authorUsername = authorUsername;
    state.labelName = labelName;
    state.milestoneTitle = milestoneTitle;
    state.notLabelName = notLabelName;
    state.notAuthorUsername = notAuthorUsername;
    state.notMilestoneTitle = notMilestoneTitle;
  },
  [types.SET_DATE_RANGE](state, { startDate, endDate }) {
    state.startDate = startDate;
    state.endDate = endDate;
  },
};
