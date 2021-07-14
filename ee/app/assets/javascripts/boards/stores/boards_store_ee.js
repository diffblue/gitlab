/* eslint-disable class-methods-use-this, no-param-reassign */
/*
  no-param-reassign is disabled because one method of BoardsStoreEE
  modify the passed parameter in conformity with non-ee BoardsStore.
*/

import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { parseBoolean } from '~/lib/utils/common_utils';
import { __, sprintf } from '~/locale';
import sidebarEventHub from '~/sidebar/event_hub';

const NO_ITERATION_TITLE = 'No+Iteration';
const NO_MILESTONE_TITLE = 'No+Milestone';

class BoardsStoreEE {
  initEESpecific(boardsStore) {
    this.$boardApp = document.getElementById('board-app');
    this.store = boardsStore;
    this.store.loadList = (listPath, listType) => this.loadList(listPath, listType);

    const superSetCurrentBoard = this.store.setCurrentBoard.bind(this.store);
    this.store.setCurrentBoard = (board) => {
      superSetCurrentBoard(board);
      this.store.state.assignees = [];
      this.store.state.milestones = [];
    };

    const baseCreate = this.store.create.bind(this.store);
    this.store.create = () => {
      baseCreate();
      if (this.$boardApp) {
        const {
          dataset: {
            boardMilestoneId,
            boardMilestoneTitle,
            boardIterationTitle,
            boardIterationId,
            boardAssigneeUsername,
            labels,
            boardWeight,
            weightFeatureAvailable,
            scopedLabels,
          },
        } = this.$boardApp;
        this.store.boardConfig = {
          milestoneId: parseInt(boardMilestoneId, 10),
          milestoneTitle: boardMilestoneTitle || '',
          iterationId: parseInt(boardIterationId, 10),
          iterationTitle: boardIterationTitle || '',
          assigneeUsername: boardAssigneeUsername,
          labels: JSON.parse(labels || []),
          weight: parseInt(boardWeight, 10),
        };
        this.store.cantEdit = [];
        this.store.weightFeatureAvailable = parseBoolean(weightFeatureAvailable);
        this.store.scopedLabels = {
          enabled: parseBoolean(scopedLabels),
        };
        if (!gon.features.graphqlBoardLists) {
          this.initBoardFilters();
        }
      }
    };

    this.store.updateFiltersUrl = (replaceState = false) => {
      if (!this.store.filter.path) {
        return;
      }
      if (replaceState) {
        window.history.replaceState(null, null, `?${this.store.filter.path}`);
      } else {
        window.history.pushState(null, null, `?${this.store.filter.path}`);
      }
    };

    this.store.updateIssueEpic = this.updateIssueEpic;

    sidebarEventHub.$on('updateWeight', this.updateWeight.bind(this));

    Object.assign(this.store, {
      updateWeight(endpoint, weight = null) {
        return axios.put(endpoint, {
          weight,
        });
      },
    });
  }

  initBoardFilters() {
    const updateFilterPath = (key, value) => {
      if (!value) return;
      const querystring = `${key}=${value}`;
      this.store.filter.path = [querystring]
        .concat(
          this.store.filter.path
            .split('&')
            .filter((param) => param.match(new RegExp(`^${key}=(.*)$`, 'g')) === null),
        )
        .join('&');
    };

    let { milestoneTitle } = this.store.boardConfig;
    if (this.store.boardConfig.milestoneId === 0) {
      milestoneTitle = NO_MILESTONE_TITLE;
    } else {
      milestoneTitle = encodeURIComponent(milestoneTitle);
    }
    if (milestoneTitle) {
      updateFilterPath('milestone_title', milestoneTitle);
      this.store.cantEdit.push('milestone');
    }

    let { iterationTitle } = this.store.boardConfig;
    if (this.store.boardConfig.iterationId === 0) {
      iterationTitle = NO_ITERATION_TITLE;
    } else {
      iterationTitle = encodeURIComponent(iterationTitle);
    }

    if (iterationTitle) {
      updateFilterPath('iteration_id', iterationTitle);
      this.store.cantEdit.push('iteration');
    }

    let { weight } = this.store.boardConfig;
    if (weight !== -1) {
      if (weight === 0) {
        weight = '0';
      }
      if (weight === -2) {
        /* eslint-disable-next-line @gitlab/require-i18n-strings */
        weight = 'None';
      }

      updateFilterPath('weight', weight);
    }

    updateFilterPath('assignee_username', this.store.boardConfig.assigneeUsername);
    if (this.store.boardConfig.assigneeUsername) {
      this.store.cantEdit.push('assignee');
    }

    const filterPath = this.store.filter.path.split('&');
    this.store.boardConfig.labels.forEach((label) => {
      const labelTitle = encodeURIComponent(label.title);
      const param = `label_name[]=${labelTitle}`;
      const labelIndex = filterPath.indexOf(param);

      if (labelIndex === -1) {
        filterPath.push(param);
      }

      this.store.cantEdit.push({
        name: 'label',
        value: label.title,
      });
    });

    this.store.filter.path = filterPath.join('&');

    this.store.updateFiltersUrl(true);
  }

  setMaxIssueCountOnList(id, maxIssueCount) {
    this.store.findList('id', id).maxIssueCount = maxIssueCount;
  }

  updateIssueEpic(issue, newEpic) {
    issue.epic = newEpic;
  }

  updateWeight({ id, value: newWeight }) {
    const { issue } = this.store.detail;
    if (issue.id === id && issue.sidebarInfoEndpoint) {
      issue.setLoadingState('weight', true);
      this.store
        .updateWeight(issue.sidebarInfoEndpoint, newWeight)
        .then((res) => res.data)
        .then((data) => {
          const lists = issue.getLists();
          const oldWeight = issue.weight;
          const weightDiff = newWeight - oldWeight;

          issue.setLoadingState('weight', false);
          issue.updateData({
            weight: data.weight,
          });
          lists.forEach((list) => {
            list.addWeight(weightDiff);
          });
        })
        .catch(() => {
          issue.setLoadingState('weight', false);
          createFlash({
            message: __('An error occurred when updating the issue weight'),
          });
        });
    }
  }

  loadList(listPath, listType) {
    if (this.store.state[listType].length) {
      return Promise.resolve();
    }

    return axios
      .get(listPath)
      .then(({ data }) => {
        this.store.state[listType] = data;
      })
      .catch(() => {
        createFlash({
          message: sprintf(__('Something went wrong while fetching %{listType} list'), {
            listType,
          }),
        });
      });
  }
}

export default new BoardsStoreEE();
