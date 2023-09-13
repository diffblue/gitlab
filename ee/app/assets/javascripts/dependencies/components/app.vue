<script>
import {
  GlButton,
  GlEmptyState,
  GlIcon,
  GlLoadingIcon,
  GlSprintf,
  GlLink,
  GlTooltipDirective,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { __, s__ } from '~/locale';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';
import { NAMESPACE_PROJECT } from '../constants';
import {
  REPORT_STATUS,
  SORT_FIELD_SEVERITY,
  SORT_FIELD_PACKAGER,
} from '../store/modules/list/constants';
import DependenciesActions from './dependencies_actions.vue';
import DependencyListIncompleteAlert from './dependency_list_incomplete_alert.vue';
import DependencyListJobFailedAlert from './dependency_list_job_failed_alert.vue';
import PaginatedDependenciesTable from './paginated_dependencies_table.vue';

export default {
  name: 'DependenciesApp',
  components: {
    DependenciesActions,
    GlButton,
    GlIcon,
    GlEmptyState,
    GlLoadingIcon,
    GlSprintf,
    GlLink,
    DependencyListIncompleteAlert,
    DependencyListJobFailedAlert,
    PaginatedDependenciesTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'emptyStateSvgPath',
    'documentationPath',
    'endpoint',
    'supportDocumentationPath',
    'exportEndpoint',
    'namespaceType',
  ],
  data() {
    return {
      isIncompleteAlertDismissed: false,
      isJobFailedAlertDismissed: false,
    };
  },
  computed: {
    ...mapState(['currentList', 'listTypes']),
    ...mapGetters([
      'generatedAtTimeAgo',
      'isInitialized',
      'isJobNotSetUp',
      'isJobFailed',
      'isIncomplete',
      'hasNoDependencies',
      'reportInfo',
      'totals',
    ]),
    ...mapState(DEPENDENCY_LIST_TYPES.all.namespace, ['pageInfo']),
    ...mapState({
      fetchingInProgress(state) {
        return state[this.currentList].fetchingInProgress;
      },
    }),
    exportButtonIcon() {
      return this.fetchingInProgress ? '' : 'export';
    },
    currentListIndex: {
      get() {
        return this.listTypes.map(({ namespace }) => namespace).indexOf(this.currentList);
      },
      set(index) {
        const { namespace } = this.listTypes[index] || {};
        this.setCurrentList(namespace);
      },
    },
    showEmptyState() {
      return this.isJobNotSetUp || this.hasNoDependencies;
    },
    emptyStateOptions() {
      const map = {
        [REPORT_STATUS.jobNotSetUp]: {
          title: __('View dependency details for your project'),
          description: __(
            'The dependency list details information about the components used within your project.',
          ),
          linkText: __('More Information'),
          link: this.documentationPath,
        },
        [REPORT_STATUS.noDependencies]: {
          title: __('Dependency List has no entries'),
          description: __(
            'It seems like the Dependency Scanning job ran successfully, but no dependencies have been detected in your project.',
          ),
          linkText: __('View supported languages and frameworks'),
          link: this.supportDocumentationPath,
        },
      };
      return map[this.reportInfo.status];
    },
    isProjectNamespace() {
      return this.namespaceType === NAMESPACE_PROJECT;
    },
    message() {
      return this.isProjectNamespace
        ? s__(
            'Dependencies|Software Bill of Materials (SBOM) based on the %{linkStart}latest successful%{linkEnd} scan',
          )
        : s__(
            'Dependencies|Software Bill of Materials (SBOM) based on the latest successful scan of each project.',
          );
    },
  },
  created() {
    this.setDependenciesEndpoint(this.endpoint);
    this.setExportDependenciesEndpoint(this.exportEndpoint);
    this.setSortField(this.isProjectNamespace ? SORT_FIELD_SEVERITY : SORT_FIELD_PACKAGER);
  },
  methods: {
    ...mapActions([
      'setDependenciesEndpoint',
      'setExportDependenciesEndpoint',
      'setSortField',
      'setCurrentList',
    ]),
    ...mapActions({
      fetchExport(dispatch) {
        dispatch(`${this.currentList}/fetchExport`);
      },
    }),
    dismissIncompleteListAlert() {
      this.isIncompleteAlertDismissed = true;
    },
    dismissJobFailedAlert() {
      this.isJobFailedAlertDismissed = true;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="!isInitialized" size="lg" class="mt-4" />

  <gl-empty-state
    v-else-if="showEmptyState"
    :title="emptyStateOptions.title"
    :svg-path="emptyStateSvgPath"
    data-testid="dependency-list-empty-state-description-content"
  >
    <template #description>
      {{ emptyStateOptions.description }}
      <gl-link target="_blank" :href="emptyStateOptions.link">
        {{ emptyStateOptions.linkText }}
      </gl-link>
    </template>
  </gl-empty-state>

  <section v-else>
    <dependency-list-incomplete-alert
      v-if="isIncomplete && !isIncompleteAlertDismissed"
      @dismiss="dismissIncompleteListAlert"
    />

    <dependency-list-job-failed-alert
      v-if="isJobFailed && !isJobFailedAlertDismissed"
      :job-path="reportInfo.jobPath"
      @dismiss="dismissJobFailedAlert"
    />

    <header class="gl-md-display-flex gl-align-items-flex-start gl-my-5 gl-overflow-auto">
      <div class="gl-mr-auto">
        <h2 class="h4 gl-mb-2 gl-mt-0 gl-display-flex gl-align-items-center">
          {{ __('Dependencies') }}
          <gl-link
            class="gl-ml-3"
            target="_blank"
            :href="documentationPath"
            :aria-label="__('Dependencies help page link')"
          >
            <gl-icon name="question-o" />
          </gl-link>
        </h2>
        <p class="gl-mb-0">
          <gl-sprintf :message="message">
            <template #link="{ content }">
              <gl-link v-if="reportInfo.jobPath" ref="jobLink" :href="reportInfo.jobPath">{{
                content
              }}</gl-link>
              <template v-else>{{ content }}</template>
            </template>
          </gl-sprintf>
          <span v-if="generatedAtTimeAgo" data-testid="time-ago-message">
            <span aria-hidden="true">&bull;</span>
            <span class="text-secondary">{{ generatedAtTimeAgo }}</span>
          </span>
        </p>
      </div>
      <gl-button
        v-gl-tooltip.hover
        :title="s__('Dependencies|Export as JSON')"
        class="gl-float-right gl-md-float-none gl-mt-3 gl-md-mt-0"
        :icon="exportButtonIcon"
        data-testid="export"
        :loading="fetchingInProgress"
        @click="fetchExport"
      >
        {{ __('Export') }}
      </gl-button>
    </header>

    <dependencies-actions class="gl-mt-3" :namespace="currentList" />

    <article>
      <paginated-dependencies-table :namespace="currentList" />
    </article>
  </section>
</template>
