<script>
import { GlButton } from '@gitlab/ui';
import vulnerabilityExternalIssueLinkCreate from 'ee/vue_shared/security_reports/graphql/vulnerability_external_issue_link_create.mutation.graphql';
import { TYPENAME_VULNERABILITY } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';

export const i18n = {
  createNewIssueLinkText: s__('VulnerabilityManagement|Create Jira issue'),
};

export default {
  i18n,
  components: {
    GlButton,
  },
  props: {
    vulnerabilityId: {
      type: Number,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: 'success',
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    async createJiraIssue() {
      this.isLoading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: vulnerabilityExternalIssueLinkCreate,
          variables: {
            input: {
              externalTracker: 'JIRA',
              linkType: 'CREATED',
              id: convertToGraphQLId(TYPENAME_VULNERABILITY, this.vulnerabilityId),
            },
          },
        });

        const { errors } = data.vulnerabilityExternalIssueLinkCreate;

        if (errors.length > 0) {
          throw new Error(errors[0]);
        }
        this.$emit('mutated');
      } catch (e) {
        this.$emit('create-jira-issue-error', e.message);
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <gl-button
    :variant="variant"
    category="secondary"
    :loading="isLoading"
    icon="external-link"
    data-testid="create-new-jira-issue"
    @click="createJiraIssue"
  >
    {{ $options.i18n.createNewIssueLinkText }}
  </gl-button>
</template>
