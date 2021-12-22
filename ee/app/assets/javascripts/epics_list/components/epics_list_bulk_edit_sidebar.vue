<script>
import { GlForm, GlFormGroup } from '@gitlab/ui';
import { uniqBy } from 'lodash';
import LabelsSelectWidget from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_vue/constants';
import csrf from '~/lib/utils/csrf';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  csrf,
  DropdownVariant,
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
     * This prop returns a unique list of labels
     * applied on all the selected epics while
     * also making sure that `id` is numeri
     * instead of GraphQL ID string.
     */
    existingSelectedLabels() {
      if (!this.checkedEpics.length) {
        return [];
      }

      return uniqBy(
        this.checkedEpics.reduce((labels, epic) => {
          if (epic.labels.nodes.length) {
            const labelsForEpic = epic.labels.nodes.map((label) => ({
              ...label,
              id: getIdFromGraphQLId(label.id),
            }));
            labels.push(...labelsForEpic);
          }
          return labels;
        }, []),
        'id',
      );
    },
  },
  methods: {
    handleSelectedLabels(labels) {
      this.selectedLabelIds = [...labels].map((label) => label.id);
      this.removedLabelIds = this.existingSelectedLabels
        .filter((label) => !this.selectedLabelIds.includes(label.id))
        .map((label) => label.id);
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
        :variant="$options.DropdownVariant.Embedded"
        @updateSelectedLabels="handleSelectedLabels"
      />
    </gl-form-group>
  </gl-form>
</template>
