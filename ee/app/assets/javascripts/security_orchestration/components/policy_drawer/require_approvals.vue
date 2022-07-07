<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__, n__, __, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

const THRESHOLD_FOR_APPROVERS = 3;

export default {
  i18n: {
    actionText: s__(
      'SecurityOrchestration|Require %{approvals} %{plural} from %{approvers} if any of the following occur:',
    ),
    additional_approvers: s__('SecurityOrchestration|, and %{count} more'),
    and: __(' and '),
    comma: __(', '),
  },
  components: {
    GlSprintf,
    GlLink,
  },
  props: {
    action: {
      type: Object,
      required: true,
    },
    approvers: {
      type: Array,
      required: true,
    },
  },
  computed: {
    approvalsRequired() {
      return this.action.approvals_required;
    },
    approvalsText() {
      return n__('approval', 'approvals', this.approvalsRequired);
    },
    displayedApprovers() {
      return this.approvers.slice(0, THRESHOLD_FOR_APPROVERS);
    },
  },
  methods: {
    isUserType(approver) {
      // eslint-disable-next-line no-underscore-dangle
      return approver.__typename === 'UserCore';
    },
    displayName(approver) {
      return this.isUserType(approver) ? approver.name : approver.fullPath;
    },
    additionalText(approver) {
      const index = this.displayedApprovers.findIndex((current) => current === approver);
      const remainingApprovers = this.approvers.length - THRESHOLD_FOR_APPROVERS;
      const displayAdditionalApprovers = remainingApprovers > 0;

      if (index === -1) {
        return '';
      }

      if (displayAdditionalApprovers) {
        if (index === this.displayedApprovers.length - 1) {
          return sprintf(this.$options.i18n.additional_approvers, {
            count: remainingApprovers,
          });
        } else if (index < this.displayedApprovers.length - 1) {
          return this.$options.i18n.comma;
        }
      } else if (index === this.displayedApprovers.length - 2) {
        return this.$options.i18n.and;
      } else if (index < this.displayedApprovers.length - 2) {
        return this.$options.i18n.comma;
      }
      return '';
    },
    attributeName(approver) {
      return this.isUserType(approver) ? 'data-user' : 'data-group';
    },
    attributeValue(approver) {
      return getIdFromGraphQLId(approver.id);
    },
  },
};
</script>

<template>
  <span>
    <gl-sprintf :message="$options.i18n.actionText">
      <template #approvals>
        {{ approvalsRequired }}
      </template>
      <template #plural>
        {{ approvalsText }}
      </template>
      <template #approvers>
        <span v-for="approver in displayedApprovers" :key="approver.id">
          <gl-link
            :href="approver.webUrl"
            :[attributeName(approver)]="attributeValue(approver)"
            target="_blank"
            class="gfm gfm-project_member js-user-link"
          >
            {{ displayName(approver) }}</gl-link
          >{{ additionalText(approver) }}
        </span>
      </template>
    </gl-sprintf>
  </span>
</template>
