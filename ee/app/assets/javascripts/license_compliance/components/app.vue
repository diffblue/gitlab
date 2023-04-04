<script>
import { GlEmptyState, GlLoadingIcon, GlLink, GlIcon } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import { LICENSE_LIST } from '../store/constants';
import DetectedLicensesTable from './detected_licenses_table.vue';
import PipelineInfo from './pipeline_info.vue';

export default {
  name: 'LicenseComplianceApp',
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlLink,
    DetectedLicensesTable,
    PipelineInfo,
    GlIcon,
  },
  inject: ['emptyStateSvgPath', 'documentationPath'],
  computed: {
    ...mapState(LICENSE_LIST, ['initialized', 'licenses', 'reportInfo']),
    ...mapState(LICENSE_MANAGEMENT, ['managedLicenses']),
    ...mapGetters(LICENSE_LIST, ['isJobSetUp', 'isJobFailed']),
    hasEmptyState() {
      return Boolean(!this.isJobSetUp || this.isJobFailed);
    },
  },
  created() {
    this.fetchLicenses();
  },
  methods: {
    ...mapActions(LICENSE_LIST, ['fetchLicenses']),
  },
};
</script>

<template>
  <gl-loading-icon v-if="!initialized" size="lg" class="mt-4" />

  <gl-empty-state
    v-else-if="hasEmptyState"
    :title="s__('Licenses|View license details for your project')"
    :svg-path="emptyStateSvgPath"
    data-qa-selector="license_compliance_empty_state_description_content"
  >
    <template #description>
      {{
        s__(
          'Licenses|The license list details information about the licenses used within your project.',
        )
      }}
      <gl-link target="_blank" :href="documentationPath">
        {{ __('More Information') }}
      </gl-link>
    </template>
  </gl-empty-state>

  <div v-else>
    <header class="my-3">
      <h2 class="h4 mb-1 gl-display-flex gl-align-items-center">
        {{ s__('Licenses|License Compliance') }}
        <gl-link :href="documentationPath" class="gl-ml-3" target="_blank">
          <gl-icon name="question-o" />
        </gl-link>
      </h2>

      <pipeline-info :path="reportInfo.jobPath" :timestamp="reportInfo.generatedAt" />
    </header>
    <detected-licenses-table />
  </div>
</template>
