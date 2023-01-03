<script>
import { GlEmptyState, GlIcon, GlLoadingIcon, GlSprintf, GlLink } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';
import { REPORT_STATUS } from '../store/modules/list/constants';
import DependenciesActions from './dependencies_actions.vue';
import DependencyListIncompleteAlert from './dependency_list_incomplete_alert.vue';
import DependencyListJobFailedAlert from './dependency_list_job_failed_alert.vue';
import PaginatedDependenciesTable from './paginated_dependencies_table.vue';

export default {
  name: 'DependenciesApp',
  components: {
    DependenciesActions,
    GlIcon,
    GlEmptyState,
    GlLoadingIcon,
    GlSprintf,
    GlLink,
    DependencyListIncompleteAlert,
    DependencyListJobFailedAlert,
    PaginatedDependenciesTable,
  },
  inject: [
    'emptyStateSvgPath',
    'documentationPath',
    'endpoint',
    'supportDocumentationPath',
    'exportEndpoint',
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
  },
  created() {
    this.setDependenciesEndpoint(this.endpoint);
    this.setExportDependenciesEndpoint(this.exportEndpoint);
    this.fetchDependencies();
  },
  methods: {
    ...mapActions([
      'setDependenciesEndpoint',
      'setExportDependenciesEndpoint',
      'fetchDependencies',
      'setCurrentList',
    ]),
    dismissIncompleteListAlert() {
      this.isIncompleteAlertDismissed = true;
    },
    dismissJobFailedAlert() {
      this.isJobFailedAlertDismissed = true;
    },
    isTabDisabled(namespace) {
      return this.totals[namespace] <= 0;
    },
    qaCountSelector(label) {
      return `dependency_list_${label.toLowerCase().replace(' ', '_')}_count`;
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
    data-qa-selector="dependency_list_empty_state_description_content"
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

    <header class="d-md-flex align-items-end my-3">
      <div class="mr-auto">
        <h2 class="h4 mb-1 mt-0 gl-display-flex gl-align-items-center">
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
        <p class="mb-0">
          <gl-sprintf
            :message="
              s__(
                'Dependencies|Software Bill of Materials (SBOM) based on the %{linkStart}latest successful%{linkEnd} scan',
              )
            "
          >
            <template #link="{ content }">
              <gl-link v-if="reportInfo.jobPath" ref="jobLink" :href="reportInfo.jobPath">{{
                content
              }}</gl-link>
              <template v-else>{{ content }}</template>
            </template>
          </gl-sprintf>
          <span v-if="generatedAtTimeAgo">
            <span aria-hidden="true">&bull;</span>
            <span class="text-secondary">{{ generatedAtTimeAgo }}</span>
          </span>
        </p>
      </div>
      <dependencies-actions class="mt-2" :namespace="currentList" />
    </header>

    <article>
      <paginated-dependencies-table :namespace="currentList" />
    </article>
  </section>
</template>
