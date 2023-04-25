<script>
import { GlAlert, GlForm, GlFormInput, GlFormCheckbox, GlButton } from '@gitlab/ui';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import {
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_CREATING,
} from '~/work_items/constants';

export default {
  components: {
    GlAlert,
    GlForm,
    GlFormInput,
    GlFormCheckbox,
    GlButton,
  },
  inject: ['fullPath'],
  data() {
    return {
      title: '',
      error: null,
      loading: false,
      confidential: false,
    };
  },
  apollo: {
    workItemTypes: {
      query: projectWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes.filter(
          (node) => node.name === WORK_ITEM_TYPE_VALUE_OBJECTIVE,
        );
      },
      error() {
        this.error = this.$options.fetchTypesErrorText;
      },
    },
  },
  computed: {
    isButtonDisabled() {
      return this.title.trim().length === 0;
    },
    createErrorText() {
      const workItemType = this.workItemTypes.find(
        (item) => item.value === this.selectedWorkItemType,
      )?.text;

      return sprintfWorkItem(I18N_WORK_ITEM_ERROR_CREATING, workItemType);
    },
    objectiveWorkItemType() {
      return this.workItemTypes[0]?.id;
    },
  },
  methods: {
    async createObjective() {
      this.loading = true;
      await this.createStandaloneWorkItem();
      this.loading = false;
    },
    async createStandaloneWorkItem() {
      try {
        const {
          data: {
            workItemCreate: { workItem },
          },
        } = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
              title: this.title,
              projectPath: this.fullPath,
              workItemTypeId: this.objectiveWorkItemType,
              confidential: this.confidential,
            },
          },
        });
        this.$emit('objective-created', { objective: workItem });
        this.resetForm();
      } catch {
        this.error = this.createErrorText;
      }
    },
    handleCancelClick() {
      this.resetForm();
      this.$emit('objective-creation-cancelled');
    },
    resetForm() {
      this.title = '';
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = null">{{ error }}</gl-alert>
    <gl-form
      class="gl-md-display-flex gl-flex-grow-1 gl-align-items-flex-start gl-border-t-0 row-content-block gl-bg-none"
      @submit.prevent="createObjective"
    >
      <div
        class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-mr-3 gl-sm-mb-5 gl-sm-mr-0!"
      >
        <gl-form-input
          ref="objectiveTitle"
          v-model.trim="title"
          type="text"
          class="gl-flex-grow-1 gl-md-mb-0! gl-mb-5"
          :autofocus="true"
          :placeholder="__('Title')"
        />
        <gl-form-checkbox v-model="confidential" name="isConfidential" class="gl-md-mt-5">{{
          s__(
            'WorkItem|This objective is confidential and should only be visible to team members with at least Reporter access',
          )
        }}</gl-form-checkbox>
      </div>
      <gl-button
        variant="confirm"
        :disabled="isButtonDisabled"
        :loading="loading"
        class="gl-mr-3"
        data-testid="create-button"
        type="submit"
      >
        {{ s__('WorkItem|Create objective') }}
      </gl-button>
      <gl-button type="button" data-testid="cancel-button" @click="handleCancelClick">
        {{ __('Cancel') }}
      </gl-button>
    </gl-form>
  </div>
</template>
