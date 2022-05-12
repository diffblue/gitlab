import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mapState, mapActions } from 'vuex';
import DateRange from '~/analytics/shared/components/daterange.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { buildGroupFromDataset, buildProjectFromDataset } from '../shared/utils';
import ProductivityAnalyticsApp from './components/app.vue';
import FilterDropdowns from './components/filter_dropdowns.vue';
import FilteredSearchProductivityAnalytics from './filtered_search_productivity_analytics';
import store from './store';
import { getLabelsEndpoint, getMilestonesEndpoint } from './utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const container = document.getElementById('js-productivity-analytics');
  const groupProjectSelectContainer = container.querySelector('.js-group-project-select-container');
  const searchBarContainer = container.querySelector('.js-search-bar');

  // we need to store the HTML content so we can reset it later
  const issueFilterHtml = searchBarContainer.querySelector('.issues-filters').innerHTML;
  const timeframeContainer = container.querySelector('.js-timeframe-container');
  const appContainer = container.querySelector('.js-productivity-analytics-app-container');

  const {
    authorUsername,
    labelName,
    milestoneTitle,
    mergedAfter,
    mergedBefore,
  } = container.dataset;

  const mergedAfterDate = new Date(mergedAfter);
  const mergedBeforeDate = new Date(mergedBefore);

  const { endpoint, emptyStateSvgPath, noAccessSvgPath } = appContainer.dataset;
  const minDate = timeframeContainer.dataset.startDate
    ? new Date(timeframeContainer.dataset.startDate)
    : null;

  const group = buildGroupFromDataset(container.dataset);
  const hideGroupDropDown = parseBoolean(container.dataset.hideGroupDropDown);

  let project = null;

  let initialData = {
    mergedAfter: mergedAfterDate,
    mergedBefore: mergedBeforeDate,
    minDate,
  };

  // let's set the initial data (from URL query params) only if we receive a valid group from BE
  if (group) {
    project = buildProjectFromDataset(container.dataset);

    initialData = {
      ...initialData,
      groupNamespace: group.full_path,
      projectPath: project ? project.path_with_namespace : null,
      authorUsername,
      labelName: labelName ? labelName.split(',') : null,
      milestoneTitle,
    };
  }

  let filterManager;

  // eslint-disable-next-line no-new
  new Vue({
    el: groupProjectSelectContainer,
    apolloProvider,
    store,
    created() {
      // let's not fetch any data by default since we might not have a valid group yet
      let skipFetch = true;

      this.setEndpoint(endpoint);

      if (group) {
        this.initFilteredSearch({
          groupNamespace: group.full_path,
          groupId: group.id,
          projectNamespace: project?.path_with_namespace || null,
          projectId: container.dataset.projectId || null,
        });

        // let's fetch data now since we do have a valid group
        skipFetch = false;
      }

      this.setInitialData({ skipFetch, data: initialData });
    },
    methods: {
      ...mapActions(['setEndpoint']),
      ...mapActions('filters', ['setInitialData']),
      onGroupSelected({ groupNamespace, groupId }) {
        this.initFilteredSearch({ groupNamespace, groupId });
      },
      onProjectSelected({ groupNamespace, groupId, projectNamespace, projectId }) {
        this.initFilteredSearch({
          groupNamespace,
          groupId,
          projectNamespace,
          projectId: getIdFromGraphQLId(projectId),
        });
      },
      initFilteredSearch({ groupNamespace, groupId, projectNamespace = '', projectId = null }) {
        // let's unbind attached event handlers first and reset the template
        if (filterManager) {
          filterManager.cleanup();
          searchBarContainer.innerHTML = issueFilterHtml;
        }

        searchBarContainer.classList.remove('hide');

        const filteredSearchInput = searchBarContainer.querySelector('.filtered-search');
        const labelsEndpoint = getLabelsEndpoint(groupNamespace, projectNamespace);
        const milestonesEndpoint = getMilestonesEndpoint(groupNamespace, projectNamespace);

        filteredSearchInput.setAttribute('data-group-id', groupId);

        if (projectId) {
          filteredSearchInput.setAttribute('data-project-id', projectId);
        }

        filteredSearchInput.setAttribute('data-labels-endpoint', labelsEndpoint);
        filteredSearchInput.setAttribute('data-milestones-endpoint', milestonesEndpoint);
        filterManager = new FilteredSearchProductivityAnalytics({ isGroup: false });
        filterManager.setup();
      },
    },
    render(h) {
      return h(FilterDropdowns, {
        props: {
          group,
          project,
          hideGroupDropDown,
        },
        on: {
          groupSelected: this.onGroupSelected,
          projectSelected: this.onProjectSelected,
        },
      });
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: timeframeContainer,
    store,
    computed: {
      ...mapState('filters', ['groupNamespace', 'startDate', 'endDate']),
    },
    methods: {
      ...mapActions('filters', ['setDateRange']),
      onDateRangeChange({ startDate, endDate }) {
        this.setDateRange({ startDate, endDate });
      },
    },
    render(h) {
      return h(DateRange, {
        props: {
          show: this.groupNamespace !== null,
          startDate: mergedAfterDate,
          endDate: mergedBeforeDate,
          minDate,
        },
        on: {
          change: this.onDateRangeChange,
        },
      });
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: appContainer,
    store,
    render(h) {
      return h(ProductivityAnalyticsApp, {
        props: {
          emptyStateSvgPath,
          noAccessSvgPath,
          hideGroupDropDown,
        },
      });
    },
  });
};
