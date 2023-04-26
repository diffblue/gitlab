<script>
import { GlAlert, GlBadge, GlEmptyState, GlFormSelect, GlLabel, GlTab, GlTabs } from '@gitlab/ui';
import { differenceBy, unionBy } from 'lodash';
import Vue from 'vue';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import LabelsSelect from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';
import { VARIANT_STANDALONE } from '~/sidebar/components/labels/labels_select_widget/constants';
import { GROUP_BY_LABEL, GROUP_BY_NONE } from '../constants';
import IterationReportIssues from './iteration_report_issues.vue';

export default {
  i18n: {
    emptyStateDescription: __('Try grouping with different labels'),
    emptyStateTitle: __('There are no issues with the selected labels'),
  },
  selectOptions: [
    {
      value: GROUP_BY_NONE,
      text: __('None'),
    },
    {
      value: GROUP_BY_LABEL,
      text: __('Label'),
    },
  ],
  VARIANT_STANDALONE,
  components: {
    GlAlert,
    GlBadge,
    GlEmptyState,
    GlFormSelect,
    GlLabel,
    GlTab,
    GlTabs,
    IterationReportIssues,
    LabelsSelect,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    hasScopedLabelsFeature: {
      type: Boolean,
      required: false,
      default: false,
    },
    iterationId: {
      type: String,
      required: true,
    },
    labelsFetchPath: {
      type: String,
      required: false,
      default: '',
    },
    namespaceType: {
      type: String,
      required: false,
      default: WORKSPACE_GROUP,
      validator: (value) => [WORKSPACE_GROUP, WORKSPACE_PROJECT].includes(value),
    },
    svgPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      issueCount: undefined,
      groupBySelection: GROUP_BY_NONE,
      selectedLabels: [],
    };
  },
  computed: {
    shouldShowFilterByLabel() {
      return this.groupBySelection === GROUP_BY_LABEL;
    },
    showEmptyState() {
      return this.selectedLabels.length && !this.labelsWithIssues.length;
    },
    labelsWithIssues() {
      return this.selectedLabels.filter((label) => label.hasIssues);
    },
    labelsWithoutIssues() {
      return this.selectedLabels.filter((label) => !label.hasIssues);
    },
  },
  methods: {
    handleIssuesUpdate({ count, labelId }) {
      if (!labelId) {
        this.issueCount = count;
        return;
      }

      const index = this.selectedLabels.findIndex((l) => l.id === labelId);

      if (index > -1) {
        const label = this.selectedLabels[index];
        label.hasIssues = Boolean(count);
        Vue.set(this.selectedLabels, index, label);
      }
    },
    handleRemoveLabel(labelId) {
      const index = this.selectedLabels.findIndex((l) => l.id === labelId);
      this.selectedLabels.splice(index, 1);
    },
    handleSelectChange() {
      if (this.groupBySelection === GROUP_BY_NONE) {
        this.selectedLabels = [];
      }
    },
    handleUpdateSelectedLabels(selectedLabels) {
      const labels = selectedLabels.map((label) => ({ ...label, hasIssues: true }));
      const labelsToAdd = labels.filter((label) => label.set);
      const labelsToRemove = labels.filter((label) => !label.set);
      const idProperty = 'id';

      this.selectedLabels = unionBy(
        differenceBy(this.selectedLabels, labelsToRemove, idProperty),
        labelsToAdd,
        idProperty,
      );
    },
    shouldShowScopedLabel(label) {
      return this.hasScopedLabelsFeature && isScopedLabel(label);
    },
  },
};
</script>

<template>
  <gl-tabs>
    <gl-tab title="Issues">
      <template #title>
        <h3 class="gl-font-base gl-m-0">{{ __('Issues') }}</h3>
        <gl-badge class="gl-ml-2" size="sm" variant="muted">{{ issueCount }}</gl-badge>
      </template>

      <div class="card gl-bg-gray-10 gl-display-flex gl-flex-direction-row gl-flex-wrap gl-px-4">
        <div class="gl-my-3 gl-mr-4">
          <label for="iteration-group-by">{{ __('Group by') }}</label>
          <gl-form-select
            id="iteration-group-by"
            v-model="groupBySelection"
            class="gl-w-auto"
            :options="$options.selectOptions"
            @change="handleSelectChange"
          />
        </div>

        <div
          v-if="shouldShowFilterByLabel"
          class="gl-display-flex gl-align-items-center gl-flex-basis-half gl-my-3"
        >
          <label class="gl-white-space-nowrap gl-mb-0 gl-mr-2">{{ __('Filter by label') }}</label>
          <labels-select
            :allow-label-create="false"
            allow-label-edit
            allow-multiselect
            :allow-scoped-labels="hasScopedLabelsFeature"
            allow-multiple-scoped-labels
            :labels-fetch-path="labelsFetchPath"
            :selected-labels="selectedLabels"
            :variant="$options.VARIANT_STANDALONE"
            @updateSelectedLabels="handleUpdateSelectedLabels"
          />
        </div>
      </div>

      <gl-alert v-if="labelsWithoutIssues.length" class="gl-mb-4" :dismissible="false">
        {{ __('Labels with no issues in this iteration:') }}
        <gl-label
          v-for="label in labelsWithoutIssues"
          :key="label.id"
          class="gl-ml-1 gl-vertical-align-middle"
          :background-color="label.color"
          :description="label.description"
          :scoped="shouldShowScopedLabel(label)"
          :target="null"
          :title="label.title"
        />
      </gl-alert>

      <gl-empty-state
        v-if="showEmptyState"
        :description="$options.i18n.emptyStateDescription"
        :svg-path="svgPath"
        :title="$options.i18n.emptyStateTitle"
      />

      <iteration-report-issues
        v-for="label in labelsWithIssues"
        :key="label.id"
        class="gl-mb-6"
        :full-path="fullPath"
        :has-scoped-labels-feature="hasScopedLabelsFeature"
        :iteration-id="iterationId"
        :label="label"
        :namespace-type="namespaceType"
        @removeLabel="handleRemoveLabel"
        @issuesUpdate="handleIssuesUpdate"
      />

      <iteration-report-issues
        v-show="!selectedLabels.length"
        :full-path="fullPath"
        :has-scoped-labels-feature="hasScopedLabelsFeature"
        :iteration-id="iterationId"
        :namespace-type="namespaceType"
        @issuesUpdate="handleIssuesUpdate"
      />
    </gl-tab>
  </gl-tabs>
</template>
