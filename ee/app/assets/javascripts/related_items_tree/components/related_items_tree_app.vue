<script>
import { GlLoadingIcon, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';

import { __, sprintf } from '~/locale';
import AddItemForm from '~/related_issues/components/add_issuable_form.vue';
import SlotSwitch from '~/vue_shared/components/slot_switch.vue';
import { OVERFLOW_AFTER } from '../constants';
import CreateEpicForm from './create_epic_form.vue';
import CreateIssueForm from './create_issue_form.vue';
import RelatedItemsTreeBody from './related_items_tree_body.vue';
import RelatedItemsTreeHeader from './related_items_tree_header.vue';
import TreeItemRemoveModal from './tree_item_remove_modal.vue';

const FORM_SLOTS = {
  addItem: 'addItem',
  createEpic: 'createEpic',
  createIssue: 'createIssue',
};

export default {
  OVERFLOW_AFTER,
  FORM_SLOTS,
  components: {
    GlLoadingIcon,
    GlIcon,
    RelatedItemsTreeHeader,
    RelatedItemsTreeBody,
    AddItemForm,
    CreateEpicForm,
    TreeItemRemoveModal,
    CreateIssueForm,
    SlotSwitch,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapState([
      'parentItem',
      'itemsFetchInProgress',
      'itemsFetchResultEmpty',
      'itemAddInProgress',
      'itemAddFailure',
      'itemAddFailureType',
      'itemAddFailureMessage',
      'itemCreateInProgress',
      'showAddItemForm',
      'showCreateEpicForm',
      'showCreateIssueForm',
      'autoCompleteEpics',
      'autoCompleteIssues',
      'pendingReferences',
      'itemInputValue',
      'issuableType',
      'epicsEndpoint',
      'issuesEndpoint',
    ]),
    ...mapGetters(['itemAutoCompleteSources', 'itemPathIdSeparator', 'directChildren']),
    disableContents() {
      return this.itemAddInProgress || this.itemCreateInProgress;
    },
    visibleForm() {
      if (this.showAddItemForm) {
        return FORM_SLOTS.addItem;
      }

      if (this.showCreateEpicForm) {
        return FORM_SLOTS.createEpic;
      }

      if (this.showCreateIssueForm) {
        return FORM_SLOTS.createIssue;
      }

      return null;
    },
    createIssuableText() {
      return sprintf(__('Create new confidential %{issuableType}'), {
        issuableType: this.issuableType,
      });
    },
    existingIssuableText() {
      return sprintf(__('Add existing confidential %{issuableType}'), {
        issuableType: this.issuableType,
      });
    },
    formSlots() {
      const { addItem, createEpic, createIssue } = this.$options.FORM_SLOTS;
      return [
        { name: addItem, value: this.existingIssuableText },
        { name: createEpic, value: this.createIssuableText },
        { name: createIssue, value: this.createIssuableText },
      ];
    },
  },
  mounted() {
    this.fetchItems({
      parentItem: this.parentItem,
    });
  },
  methods: {
    ...mapActions([
      'fetchItems',
      'toggleAddItemForm',
      'toggleCreateEpicForm',
      'toggleCreateIssueForm',
      'setPendingReferences',
      'addPendingReferences',
      'removePendingReference',
      'setItemInputValue',
      'addItem',
      'createItem',
      'createNewIssue',
      'fetchProjects',
    ]),
    getRawRefs(value) {
      return value.split(/\s+/).filter((ref) => ref.trim().length > 0);
    },
    handlePendingItemRemove(index) {
      this.removePendingReference(index);
    },
    handleAddItemFormInput({ untouchedRawReferences, touchedReference }) {
      this.addPendingReferences(untouchedRawReferences);
      this.setItemInputValue(`${touchedReference}`);
    },
    handleAddItemFormBlur(newValue) {
      this.addPendingReferences(this.getRawRefs(newValue));
      this.setItemInputValue('');
    },
    handleAddItemFormSubmit(event) {
      this.handleAddItemFormBlur(event.pendingReferences);

      if (this.pendingReferences.length > 0) {
        this.addItem();
      }
    },
    handleCreateEpicFormSubmit({ value, groupFullPath }) {
      this.createItem({
        itemTitle: value,
        groupFullPath,
      });
    },
    handleAddItemFormCancel() {
      this.toggleAddItemForm({ toggleState: false });
      this.setPendingReferences([]);
      this.setItemInputValue('');
    },
    handleCreateEpicFormCancel() {
      this.toggleCreateEpicForm({ toggleState: false });
      this.setItemInputValue('');
    },
  },
};
</script>

<template>
  <div class="related-items-tree-container">
    <div v-if="itemsFetchInProgress" class="mt-2">
      <gl-loading-icon size="md" />
    </div>
    <div
      v-else
      class="related-items-tree card card-slim border-top-0"
      :class="{
        'disabled-content': disableContents,
        'overflow-auto': directChildren.length > $options.OVERFLOW_AFTER,
      }"
    >
      <related-items-tree-header :class="{ 'border-bottom-0': itemsFetchResultEmpty }" />
      <slot-switch
        v-if="visibleForm && parentItem.confidential"
        :active-slot-names="[visibleForm]"
        class="gl-p-5 gl-pb-0"
      >
        <template v-for="slot in formSlots" #[slot.name]>
          <h6 :key="slot.name">
            {{ slot.value }}
            <gl-icon
              v-gl-tooltip.hover
              name="question-o"
              class="gl-text-gray-500"
              :title="
                __(
                  'The parent epic is confidential and can only contain confidential epics and issues',
                )
              "
            />
          </h6>
        </template>
      </slot-switch>
      <slot-switch
        v-if="visibleForm"
        :active-slot-names="[visibleForm]"
        class="card-body add-item-form-container"
        :class="{
          'border-bottom-0': itemsFetchResultEmpty,
          'gl-show-field-errors': itemAddFailure,
        }"
      >
        <template #[$options.FORM_SLOTS.addItem]>
          <add-item-form
            :issuable-type="issuableType"
            :input-value="itemInputValue"
            :is-submitting="itemAddInProgress"
            :pending-references="pendingReferences"
            :auto-complete-sources="itemAutoCompleteSources"
            :path-id-separator="itemPathIdSeparator"
            :has-error="itemAddFailure"
            :item-add-failure-type="itemAddFailureType"
            :item-add-failure-message="itemAddFailureMessage"
            :confidential="parentItem.confidential"
            @pendingIssuableRemoveRequest="handlePendingItemRemove"
            @addIssuableFormInput="handleAddItemFormInput"
            @addIssuableFormBlur="handleAddItemFormBlur"
            @addIssuableFormSubmit="handleAddItemFormSubmit"
            @addIssuableFormCancel="handleAddItemFormCancel"
          />
        </template>
        <template #[$options.FORM_SLOTS.createEpic]>
          <create-epic-form
            :is-submitting="itemCreateInProgress"
            @createEpicFormSubmit="handleCreateEpicFormSubmit"
            @createEpicFormCancel="handleCreateEpicFormCancel"
          />
        </template>
        <template #[$options.FORM_SLOTS.createIssue]>
          <create-issue-form
            @cancel="toggleCreateIssueForm({ toggleState: false })"
            @submit="createNewIssue"
          />
        </template>
      </slot-switch>
      <related-items-tree-body
        v-if="!itemsFetchResultEmpty"
        :parent-item="parentItem"
        :children="directChildren"
      />
      <tree-item-remove-modal />
    </div>
  </div>
</template>
