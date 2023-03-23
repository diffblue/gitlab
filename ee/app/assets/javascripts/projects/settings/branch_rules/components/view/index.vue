<script>
import { sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import RuleViewFoss from '~/projects/settings/branch_rules/components/view/index.vue';
import {
  I18N,
  APPROVALS_HELP_PATH,
  STATUS_CHECKS_HELP_PATH,
} from '~/projects/settings/branch_rules/components/view/constants';

const approvalsHelpDocLink = helpPagePath(APPROVALS_HELP_PATH);
const statusChecksHelpDocLink = helpPagePath(STATUS_CHECKS_HELP_PATH);

// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
// eslint-disable-next-line @gitlab/no-runtime-template-compiler
export default {
  name: 'EERuleView',
  extends: RuleViewFoss,
  i18n: I18N,
  approvalsHelpDocLink,
  statusChecksHelpDocLink,
  inject: {
    approvalRulesPath: {
      default: '',
    },
    statusChecksPath: {
      default: '',
    },
  },
  computed: {
    approvalsHeader() {
      const total = this.approvalRules.reduce(
        (sum, { approvalsRequired }) => sum + approvalsRequired,
        0,
      );
      return sprintf(this.$options.i18n.approvalsHeader, {
        total,
      });
    },
    statusChecksHeader() {
      return sprintf(this.$options.i18n.statusChecksHeader, {
        total: this.statusChecks.length,
      });
    },
  },
};
</script>
