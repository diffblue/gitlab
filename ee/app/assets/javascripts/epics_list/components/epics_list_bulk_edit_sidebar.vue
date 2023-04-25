<script>
import { GlForm, GlFormGroup } from '@gitlab/ui';
import { intersectionBy, xorBy, unionBy } from 'lodash';
import LabelsSelectWidget from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';
import { VARIANT_EMBEDDED } from '~/sidebar/components/labels/labels_select_widget/constants';
import csrf from '~/lib/utils/csrf';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  csrf,
  VARIANT_EMBEDDED,
  getIdFromGraphQLId,
  components: {
    GlForm,
    GlFormGroup,
    LabelsSelectWidget,
  },
  inject: ['labelsManagePath', 'labelsFetchPath'],
  props: {
    checkedEpics: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      selectedLabelIds: [],
      removedLabelIds: [],
    };
  },
  computed: {
    /**
     * This prop returns a list of labels which
     * are applied on all the selected epics while
     * also making sure that `id` is numeric
     * instead of GraphQL ID string.
     *
     * If any epic selected has no labels, or
     * has labels which are not present in rest
     * of the selection, list returned will be empty.
     */
    existingSelectedLabels() {
      if (!this.checkedEpics.length) {
        return [];
      }

      const transformLabelFn = (label, extras) => ({
        ...label,
        ...extras,
        id: getIdFromGraphQLId(label.id),
      });

      const labelsPerEpic = [...this.checkedEpics.map((epic) => epic.labels.nodes)];
      const allLabels = unionBy(...labelsPerEpic, 'id');
      const hasEpicWithNoLabels = labelsPerEpic.some((labels) => !labels.length);

      // Collect all the labels which are present in all the selected epics
      // and make them `set` (show '✓' on UI)
      const commonLabels = intersectionBy(...labelsPerEpic, 'id').map((label) =>
        transformLabelFn(label, { set: true }),
      );

      // Collect all the labels which are not present in more than one selected epic
      // and make them `indeterminate` (show '-' on UI)
      const uncommonLabels = xorBy(...labelsPerEpic, 'id').map((label) =>
        transformLabelFn(label, { indeterminate: true }),
      );

      if (commonLabels.length === allLabels.length) {
        // Selected epics have same set of labels
        return commonLabels;
      } else if (uncommonLabels.length === allLabels.length) {
        // Selected epics have distinct set of labels
        return uncommonLabels;
      } else if (commonLabels.length || uncommonLabels.length) {
        // Selected epics have only some labels in common
        return commonLabels.concat(
          xorBy(commonLabels, allLabels, 'id').map((label) =>
            transformLabelFn(label, { indeterminate: true }),
          ),
        );
      } else if (hasEpicWithNoLabels || !commonLabels.length || !uncommonLabels.length) {
        // Selected epics have no label in common
        return allLabels.map((label) => transformLabelFn(label, { indeterminate: true }));
      }

      // Selected epics have labels that can be categorised
      // in two groups; common and uncommon.
      return unionBy(uncommonLabels, commonLabels, 'id');
    },
  },
  methods: {
    handleSelectedLabels(touchedLabels) {
      if (touchedLabels.length) {
        this.selectedLabelIds = touchedLabels.filter((label) => label.set).map((label) => label.id);
        this.removedLabelIds = touchedLabels.filter((label) => !label.set).map((label) => label.id);
      } else {
        this.selectedLabelIds = [];
        this.removedLabelIds = this.existingSelectedLabels.map((label) => label.id);
      }
    },
    handleFormSubmitted() {
      const bulkUpdateData = {
        issuable_ids: this.checkedEpics.map((epic) => getIdFromGraphQLId(epic.id)).join(','),
        add_label_ids: this.selectedLabelIds,
        remove_label_ids: this.removedLabelIds,
      };

      this.$emit('bulk-update', bulkUpdateData);
    },
  },
};
</script>

<template>
  <gl-form id="epics-list-bulk-edit" @submit.prevent="handleFormSubmitted">
    <gl-form-group :label="__('Labels')" class="block gl-p-0! gl-m-auto gl-mt-6">
      <labels-select-widget
        :allow-label-edit="true"
        :allow-multiselect="true"
        :allow-scoped-labels="true"
        :selected-labels="existingSelectedLabels"
        :labels-fetch-path="labelsFetchPath"
        :labels-manage-path="labelsManagePath"
        :variant="$options.VARIANT_EMBEDDED"
        @onDropdownClose="handleSelectedLabels"
      />
    </gl-form-group>
  </gl-form>
</template>
