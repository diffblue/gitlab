<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__, n__, __, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';

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
    isRoleType(approver) {
      return typeof approver === 'string';
    },
    isUserType(approver) {
      return approver?.id?.includes(TYPENAME_USER);
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
    attributeValue(approver) {
      // The data-user attribute is required for the user popover
      // Since the popover is only for users, this method returns false if not a user to hide the
      // data-user attribute
      return this.isUserType(approver) ? getIdFromGraphQLId(approver.id) : false;
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
        <span v-for="approver in displayedApprovers" :key="approver.id || approver">
          <span v-if="isRoleType(approver)" :data-testid="approver">{{ approver }}</span>
          <gl-link
            v-else
            :href="approver.webUrl"
            :data-user="attributeValue(approver)"
            :data-testid="approver.id"
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
