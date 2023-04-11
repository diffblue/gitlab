<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';

import { __, s__, sprintf } from '~/locale';
import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import deleteComplianceFrameworkMutation from '../graphql/mutations/delete_compliance_framework.mutation.graphql';

export default {
  components: {
    GlModal,
    GlSprintf,
  },
  inject: ['groupPath'],
  props: {
    name: {
      type: String,
      required: false,
      default: null,
    },
    id: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    title() {
      return sprintf(this.$options.i18n.title, { framework: this.name });
    },
  },
  methods: {
    async deleteFramework() {
      this.reportDeleting();

      try {
        const { id } = this;
        const {
          data: { destroyComplianceFramework },
        } = await this.$apollo.mutate({
          mutation: deleteComplianceFrameworkMutation,
          variables: {
            input: {
              id,
            },
          },
          awaitRefetchQueries: true,
          refetchQueries: [
            {
              query: getComplianceFrameworkQuery,
              variables: {
                fullPath: this.groupPath,
              },
            },
          ],
        });

        const [error] = destroyComplianceFramework.errors;

        if (error) {
          this.reportError(new Error(error));
        } else {
          this.reportSuccess(id);
        }
      } catch (error) {
        this.reportError(error);
      }
    },
    reportDeleting() {
      this.$emit('deleting');
    },
    reportError(error) {
      Sentry.captureException(error);
      this.$emit('error');
    },
    reportSuccess(id) {
      this.$emit('delete', id);
    },
    show() {
      this.$refs.modal.show();
    },
  },
  i18n: {
    title: s__('ComplianceFrameworks|Delete compliance framework %{framework}'),
    message: s__(
      'ComplianceFrameworks|You are about to permanently delete the compliance framework %{framework} from all projects which currently have it applied, which may remove other functionality. This cannot be undone.',
    ),
  },
  buttonProps: {
    primary: {
      text: s__('ComplianceFrameworks|Delete framework'),
      attributes: { category: 'primary', variant: 'danger' },
    },
    cancel: {
      text: __('Cancel'),
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    :title="title"
    modal-id="delete-framework-modal"
    :action-primary="$options.buttonProps.primary"
    :action-cancel="$options.buttonProps.cancel"
    @primary="deleteFramework"
  >
    <gl-sprintf :message="$options.i18n.message">
      <template #framework>
        <strong>{{ name }}</strong>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
