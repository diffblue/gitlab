<script>
import { GlAlert, GlForm, GlFormCombobox, GlButton } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import createWorkItemMutation from '../../graphql/create_work_item.mutation.graphql';
import { WORK_ITEM_TYPE_IDS } from '../../constants';

export default {
  components: {
    GlAlert,
    GlForm,
    GlFormCombobox,
    GlButton,
  },
  inject: ['projectPath'],
  props: {
    issuableGid: {
      type: String,
      required: false,
      default: null,
    },
    childrenIds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  apollo: {
    availableWorkItems: {
      query: projectWorkItemsQuery,
      debounce: 200,
      variables() {
        return {
          projectPath: this.projectPath,
          searchTerm: this.search?.title || this.search,
          types: ['TASK'],
        };
      },
      skip() {
        return this.search.length === 0;
      },
      update(data) {
        return data.workspace.workItems.edges
          .filter((wi) => !this.childrenIds.includes(wi.node.id))
          .map((wi) => wi.node);
      },
    },
  },
  data() {
    return {
      availableWorkItems: [],
      search: '',
      error: null,
      childToCreateTitle: null,
    };
  },
  computed: {
    actionsList() {
      return [
        {
          label: this.$options.i18n.createChildOptionLabel,
          fn: () => {
            this.childToCreateTitle = this.search?.title || this.search;
          },
        },
      ];
    },
    addOrCreateButtonLabel() {
      return this.childToCreateTitle
        ? this.$options.i18n.createChildOptionLabel
        : this.$options.i18n.addTaskButtonLabel;
    },
    addOrCreateMethod() {
      return this.childToCreateTitle ? this.createChild : this.addChild;
    },
  },
  methods: {
    getIdFromGraphQLId,
    unsetError() {
      this.error = null;
    },
    addChild() {
      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.issuableGid,
              hierarchyWidget: {
                childrenIds: [this.search.id],
              },
            },
          },
        })
        .then(({ data }) => {
          if (data.workItemUpdate?.errors?.length) {
            [this.error] = data.workItemUpdate.errors;
          } else {
            this.unsetError();
            this.$emit('addWorkItemChild', this.search);
          }
        })
        .catch(() => {
          this.error = this.$options.i18n.addChildErrorMessage;
        })
        .finally(() => {
          this.search = '';
        });
    },
    createChild() {
      this.$apollo
        .mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
              title: this.search?.title || this.search,
              projectPath: this.projectPath,
              workItemTypeId: WORK_ITEM_TYPE_IDS.TASK,
              hierarchyWidget: {
                parentId: this.issuableGid,
              },
            },
          },
        })
        .then(({ data }) => {
          if (data.workItemCreate?.errors?.length) {
            [this.error] = data.workItemCreate.errors;
          } else {
            this.unsetError();
            this.$emit('addWorkItemChild', data.workItemCreate.workItem);
          }
        })
        .catch(() => {
          this.error = this.$options.i18n.createChildErrorMessage;
        })
        .finally(() => {
          this.search = '';
          this.childToCreateTitle = null;
        });
    },
  },
  i18n: {
    inputLabel: __('Children'),
    addTaskButtonLabel: s__('WorkItem|Add task'),
    addChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to add a child. Please try again.',
    ),
    createChildOptionLabel: s__('WorkItem|Create task'),
    createChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to create a child. Please try again.',
    ),
  },
};
</script>

<template>
  <gl-form
    class="gl-mb-3 gl-bg-white gl-mb-3 gl-py-3 gl-px-4 gl-border gl-border-gray-100 gl-rounded-base"
  >
    <gl-alert v-if="error" variant="danger" class="gl-mb-3" @dismiss="unsetError">
      {{ error }}
    </gl-alert>
    <gl-form-combobox
      v-model="search"
      :token-list="availableWorkItems"
      match-value-to-attr="title"
      class="gl-mb-4"
      :label-text="$options.i18n.inputLabel"
      :action-list="actionsList"
      label-sr-only
      autofocus
    >
      <template #result="{ item }">
        <div class="gl-display-flex">
          <div class="gl-text-gray-400 gl-mr-4">{{ getIdFromGraphQLId(item.id) }}</div>
          <div>{{ item.title }}</div>
        </div>
      </template>
      <template #action="{ item }">
        <span class="gl-text-blue-500">{{ item.label }}</span>
      </template>
    </gl-form-combobox>
    <gl-button category="secondary" data-testid="add-child-button" @click="addOrCreateMethod">
      {{ addOrCreateButtonLabel }}
    </gl-button>
    <gl-button category="tertiary" @click="$emit('cancel')">
      {{ s__('WorkItem|Cancel') }}
    </gl-button>
  </gl-form>
</template>
