<script>
import { GlLoadingIcon, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import AddItemForm from '~/related_issues/components/add_issuable_form.vue';
import SlotSwitch from '~/vue_shared/components/slot_switch.vue';
import { ITEM_TABS, OVERFLOW_AFTER, i18nConfidentialParent } from '../constants';
import CreateEpicForm from './create_epic_form.vue';
import CreateIssueForm from './create_issue_form.vue';
import RelatedItemsTreeBody from './related_items_tree_body.vue';
import RelatedItemsTreeHeader from './related_items_tree_header.vue';
import RelatedItemsTreeActions from './related_items_tree_actions.vue';
import RelatedItemsRoadmapApp from './related_items_roadmap_app.vue';
import TreeItemRemoveModal from './tree_item_remove_modal.vue';

const FORM_SLOTS = {
  addItem: 'addItem',
  createEpic: 'createEpic',
  createIssue: 'createIssue',
};

export default {
  OVERFLOW_AFTER,
  FORM_SLOTS,
  ITEM_TABS,
  i18nConfidentialParent,
  components: {
    GlLoadingIcon,
    GlIcon,
    RelatedItemsTreeHeader,
    RelatedItemsTreeBody,
    RelatedItemsTreeActions,
    RelatedItemsRoadmapApp,
    AddItemForm,
    CreateEpicForm,
    TreeItemRemoveModal,
    CreateIssueForm,
    SlotSwitch,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      activeTab: ITEM_TABS.TREE,
      showRelatedItems: true,
    };
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
    enableEpicsAutoComplete() {
      return this.issuableType === TYPE_EPIC && this.autoCompleteEpics;
    },
    enableIssuesAutoComplete() {
      return this.issuableType === TYPE_ISSUE && this.autoCompleteIssues;
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
    handleTabChange(value) {
      this.activeTab = value;
    },
    handleRelatedItemsView(value) {
      this.showRelatedItems = value;
    },
  },
};
</script>

<template>
  <div class="related-items-tree-container">
    <div
      class="related-items-tree card card-slim gl-mt-4 gl-mb-0 gl-bg-gray-10"
      :class="{
        'disabled-content': disableContents,
        'overflow-auto': directChildren.length > $options.OVERFLOW_AFTER,
      }"
    >
      <related-items-tree-header
        :class="{ 'border-bottom-0': itemsFetchResultEmpty || !showRelatedItems }"
        @toggleRelatedItemsView="handleRelatedItemsView"
      />
      <slot-switch
        v-if="visibleForm && parentItem.confidential"
        :active-slot-names="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
          visibleForm,
        ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        class="gl-p-5 gl-pb-0"
      >
        <template v-for="slot in formSlots" #[slot.name]>
          <h6 :key="slot.name">
            {{ slot.value }}
            <gl-icon
              v-gl-tooltip.hover
              name="question-o"
              class="gl-text-gray-500"
              :title="$options.i18nConfidentialParent[parentItem.type]"
            />
          </h6>
        </template>
      </slot-switch>
      <slot-switch
        v-if="visibleForm"
        :active-slot-names="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
          visibleForm,
        ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        class="card-body add-item-form-container gl-m-4 gl-mb-1 gl-bg-white gl-border-1 gl-border-solid gl-border-gray-100 gl-rounded-base"
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
            :auto-complete-epics="enableEpicsAutoComplete"
            :auto-complete-issues="enableIssuesAutoComplete"
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
      <div v-if="itemsFetchInProgress" class="gl-px-3 gl-py-4">
        <gl-loading-icon size="sm" />
      </div>
      <div
        v-else-if="!itemsFetchResultEmpty && showRelatedItems"
        data-testid="related-items-container"
      >
        <related-items-tree-actions :active-tab="activeTab" @tab-change="handleTabChange" />

        <related-items-tree-body
          v-if="activeTab === $options.ITEM_TABS.TREE"
          :parent-item="parentItem"
          :children="directChildren"
        />
        <related-items-roadmap-app v-if="activeTab === $options.ITEM_TABS.ROADMAP" />
      </div>
      <tree-item-remove-modal />
    </div>
  </div>
</template>
