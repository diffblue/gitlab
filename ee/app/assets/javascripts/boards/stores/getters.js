import { find } from 'lodash';
import { ListType } from '~/boards/constants';
import gettersCE from '~/boards/stores/getters';
import { TYPE_EPIC } from '~/issues/constants';

export default {
  ...gettersCE,

  isSwimlanesOn: (state) => {
    return Boolean(gon?.licensed_features?.swimlanes && state.isShowingEpicsSwimlanes);
  },

  getListByTypeId: (state) => ({ assigneeId, labelId, milestoneId, iterationId }) => {
    if (assigneeId) {
      return find(
        state.boardLists,
        (l) => l.listType === ListType.assignee && l.assignee?.id === assigneeId,
      );
    }

    if (labelId) {
      return find(
        state.boardLists,
        (l) => l.listType === ListType.label && l.label?.id === labelId,
      );
    }

    if (milestoneId) {
      return find(
        state.boardLists,
        (l) => l.listType === ListType.milestone && l.milestone?.id === milestoneId,
      );
    }

    if (iterationId) {
      return find(
        state.boardLists,
        (l) => l.listType === ListType.iteration && l.iteration?.id === iterationId,
      );
    }

    return null;
  },

  getIssuesByEpic: (state, getters) => (listId, epicId) => {
    return getters
      .getBoardItemsByList(listId)
      .filter((issue) => issue.epic && issue.epic.id === epicId);
  },

  getUnassignedIssues: (state, getters) => (listId) => {
    return getters.getBoardItemsByList(listId).filter((i) => Boolean(i.epic) === false);
  },

  isEpicBoard: (state) => {
    return state.issuableType === TYPE_EPIC;
  },
};
