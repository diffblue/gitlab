<script>
import {
  GlEmptyState,
  GlButton,
  GlModalDirective,
  GlLoadingIcon,
  GlAlert,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import { addEscalationPolicyModalId } from '../constants';
import getEscalationPoliciesQuery from '../graphql/queries/get_escalation_policies.query.graphql';
import { parsePolicy } from '../utils';
import AddEscalationPolicyModal from './add_edit_escalation_policy_modal.vue';
import EscalationPolicy from './escalation_policy.vue';

export const i18n = {
  title: s__('EscalationPolicies|Escalation policies'),
  addPolicy: s__('EscalationPolicies|Add policy'),
  emptyState: {
    title: s__('EscalationPolicies|Create an escalation policy in GitLab'),
    description: s__(
      "EscalationPolicies|Choose who to email if those contacted first about an alert don't respond.",
    ),
    unauthorizedDescription: s__(
      "EscalationPolicies|Choose who to email if those contacted first about an alert don't respond. To access this feature, ask %{linkStart}a project Owner%{linkEnd} to grant you at least the Maintainer role.",
    ),
    button: s__('EscalationPolicies|Add an escalation policy'),
  },
  policyCreatedAlert: {
    title: s__('EscalationPolicies|Escalation policy successfully created'),
    message: s__(
      'EscalationPolicies|When a new alert is received, the users specified in the policy receive an email.',
    ),
  },
};

export default {
  i18n,
  addEscalationPolicyModalId,
  components: {
    GlEmptyState,
    GlButton,
    GlLoadingIcon,
    GlAlert,
    GlSprintf,
    GlLink,
    AddEscalationPolicyModal,
    EscalationPolicy,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: [
    'projectPath',
    'emptyEscalationPoliciesSvgPath',
    'userCanCreateEscalationPolicy',
    'accessLevelDescriptionPath',
  ],
  data() {
    return {
      escalationPolicies: [],
      isCreatedAlertShown: false,
    };
  },
  apollo: {
    escalationPolicies: {
      query: getEscalationPoliciesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update({ project }) {
        return project?.incidentManagementEscalationPolicies?.nodes.map(parsePolicy) ?? [];
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.escalationPolicies.loading;
    },
    hasPolicies() {
      return this.escalationPolicies.length;
    },
  },
  methods: {
    showCreatedAlert(alertShown) {
      this.isCreatedAlertShown = alertShown;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-3" />

    <template v-else-if="hasPolicies">
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <h2>{{ $options.i18n.title }}</h2>
      </div>

      <gl-alert
        v-if="isCreatedAlertShown"
        variant="success"
        :title="$options.i18n.policyCreatedAlert.title"
        @dismiss="showCreatedAlert(false)"
      >
        {{ $options.i18n.policyCreatedAlert.message }}
      </gl-alert>

      <escalation-policy
        v-for="(policy, index) in escalationPolicies"
        :key="policy.id"
        :policy="policy"
        :index="index"
      />
    </template>

    <gl-empty-state
      v-else
      :title="$options.i18n.emptyState.title"
      :svg-path="emptyEscalationPoliciesSvgPath"
    >
      <template #description>
        <p v-if="userCanCreateEscalationPolicy">
          {{ $options.i18n.emptyState.description }}
        </p>
        <gl-sprintf v-else :message="$options.i18n.emptyState.unauthorizedDescription">
          <template #link="{ content }">
            <gl-link :href="accessLevelDescriptionPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
      <template v-if="userCanCreateEscalationPolicy" #actions>
        <gl-button v-gl-modal="$options.addEscalationPolicyModalId" variant="confirm">
          {{ $options.i18n.emptyState.button }}
        </gl-button>
      </template>
    </gl-empty-state>
    <add-escalation-policy-modal
      :modal-id="$options.addEscalationPolicyModalId"
      @policy-created="showCreatedAlert(true)"
    />
  </div>
</template>
