<script>
import { GlAlert, GlFormInput, GlButton } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
    GlFormInput,
    GlButton,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['fullPath'],
  data() {
    return {
      title: '',
      error: null,
      loading: false,
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
    fetchByIid() {
      return this.glFeatures.useIidInWorkItemsPath;
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
    <form
      class="gl-md-display-flex gl-flex-grow-1 gl-border-t-0 row-content-block"
      @submit.prevent="createObjective"
    >
      <gl-form-input
        v-model.trim="title"
        type="text"
        class="gl-flex-grow-1 gl-mr-3"
        :placeholder="__('Title')"
      />
      <gl-button
        type="button"
        data-testid="cancel-button"
        class="gl-mr-3"
        @click="handleCancelClick"
      >
        {{ __('Cancel') }}
      </gl-button>
      <gl-button
        variant="confirm"
        :disabled="isButtonDisabled"
        :loading="loading"
        data-testid="create-button"
        type="submit"
      >
        {{ s__('WorkItem|Create Objective') }}
      </gl-button>
    </form>
  </div>
</template>
