<script>
import { GlButton } from '@gitlab/ui';
import { WORK_ITEM_TYPE_VALUE_EPIC } from '~/work_items/constants';
import WorkItemsListApp from '~/work_items/list/components/work_items_list_app.vue';
import CreateWorkItemForm from '../../components/create_work_item_form.vue';

export default {
  WORK_ITEM_TYPE_VALUE_EPIC,
  components: {
    CreateWorkItemForm,
    GlButton,
    WorkItemsListApp,
  },
  inject: ['hasEpicsFeature'],
  data() {
    return {
      showEpicCreationForm: false,
    };
  },
  methods: {
    handleCreated({ workItem }) {
      if (workItem.id) {
        // Refresh results on list
        this.showEpicCreationForm = false;
        this.$refs.workItemsListApp.$apollo.queries.workItems.refetch();
      }
    },
    hideForm() {
      this.showEpicCreationForm = false;
    },
    showForm() {
      this.showEpicCreationForm = true;
    },
  },
};
</script>

<template>
  <work-items-list-app ref="workItemsListApp">
    <template v-if="hasEpicsFeature" #nav-actions>
      <gl-button variant="confirm" @click="showForm">
        {{ __('Create epic') }}
      </gl-button>
    </template>
    <template v-if="hasEpicsFeature && showEpicCreationForm" #list-body>
      <create-work-item-form
        is-group
        :work-item-type="$options.WORK_ITEM_TYPE_VALUE_EPIC"
        @created="handleCreated"
        @hide="hideForm"
      />
    </template>
  </work-items-list-app>
</template>
