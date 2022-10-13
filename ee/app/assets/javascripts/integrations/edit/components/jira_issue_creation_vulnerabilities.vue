<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlFormCheckbox,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import { billingPlans, billingPlanNames } from '~/integrations/constants';
import { defaultJiraIssueTypeId } from '../constants';

export const i18n = {
  checkbox: {
    label: s__('JiraService|Enable Jira issue creation from vulnerabilities'),
    description: s__(
      'JiraService|Issues created from vulnerabilities in this project will be Jira issues, even if GitLab issues are enabled.',
    ),
  },
  issueTypeSelect: {
    description: s__('JiraService|Define the type of Jira issue to create from a vulnerability.'),
    defaultText: s__('JiraService|Select issue type'),
  },
  fetchIssueTypesButtonLabel: s__('JiraService|Fetch issue types for this Jira project'),
  fetchIssueTypesErrorMessage: s__('JiraService|An error occurred while fetching issue list'),
  projectKeyWarnings: {
    missing: s__('JiraService|Project key is required to generate issue types'),
    changed: s__('JiraService|Project key changed, refresh list'),
  },
};

export default {
  i18n,
  components: {
    GlAlert,
    GlBadge,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlFormCheckbox,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    showFullFeature: {
      type: Boolean,
      required: false,
      default: true,
    },
    projectKey: {
      type: String,
      required: false,
      default: '',
    },
    initialIssueTypeId: {
      type: String,
      required: false,
      default: defaultJiraIssueTypeId,
    },
    initialIsEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoadingErrorAlertDimissed: false,
      projectKeyForCurrentIssues: '',
      isJiraVulnerabilitiesEnabled: this.initialIsEnabled,
      selectedJiraIssueType: null,
    };
  },
  computed: {
    ...mapGetters(['isInheriting', 'propsSource']),
    ...mapState(['jiraIssueTypes', 'isLoadingJiraIssueTypes', 'loadingJiraIssueTypesErrorMessage']),
    checkboxDisabled() {
      return !this.showFullFeature || this.isInheriting;
    },
    initialJiraIssueType() {
      return this.jiraIssueTypes?.find(({ id }) => id === this.initialIssueTypeId) || {};
    },
    checkedIssueType() {
      return this.selectedJiraIssueType || this.initialJiraIssueType;
    },
    hasProjectKeyChanged() {
      return this.projectKeyForCurrentIssues && this.projectKey !== this.projectKeyForCurrentIssues;
    },
    shouldShowLoadingErrorAlert() {
      return !this.isLoadingErrorAlertDimissed && this.loadingJiraIssueTypesErrorMessage;
    },
    projectKeyWarning() {
      const {
        $options: {
          i18n: { projectKeyWarnings },
        },
      } = this;

      if (!this.projectKey) {
        return projectKeyWarnings.missing;
      }
      if (this.hasProjectKeyChanged) {
        return projectKeyWarnings.changed;
      }
      return '';
    },
    ultimateBadgeText() {
      return billingPlanNames[billingPlans.ULTIMATE];
    },
  },
  mounted() {
    if (this.initialIsEnabled) {
      this.requestJiraIssueTypes();
    }
  },
  methods: {
    requestJiraIssueTypes() {
      this.$emit('request-jira-issue-types');
    },
    handleLoadJiraIssueTypesClick() {
      this.requestJiraIssueTypes();
      this.projectKeyForCurrentIssues = this.projectKey;
      this.isLoadingErrorAlertDimissed = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-form-checkbox
      v-model="isJiraVulnerabilitiesEnabled"
      data-testid="enable-jira-vulnerabilities"
      :disabled="checkboxDisabled"
      data-qa-selector="service_jira_enable_vulnerabilities_checkbox"
    >
      <span>{{ $options.i18n.checkbox.label }}</span
      ><gl-badge
        :href="propsSource.aboutPricingUrl"
        target="_blank"
        rel="noopener noreferrer"
        variant="tier"
        icon="license"
        class="gl-vertical-align-middle gl-mt-n2 gl-ml-2"
      >
        {{ ultimateBadgeText }}
      </gl-badge>
      <template #help>
        {{ $options.i18n.checkbox.description }}
      </template>
    </gl-form-checkbox>

    <template v-if="showFullFeature">
      <input
        name="service[vulnerabilities_enabled]"
        type="hidden"
        :value="isJiraVulnerabilitiesEnabled"
      />
      <div
        v-if="isJiraVulnerabilitiesEnabled"
        class="gl-mt-3 gl-ml-6"
        data-testid="issue-type-section"
      >
        <p class="gl-mb-3">{{ $options.i18n.issueTypeSelect.description }}</p>
        <gl-alert
          v-if="shouldShowLoadingErrorAlert"
          class="gl-mb-5"
          variant="danger"
          :title="$options.i18n.fetchIssueTypesErrorMessage"
          @dismiss="isLoadingErrorAlertDimissed = true"
        >
          {{ loadingJiraIssueTypesErrorMessage }}
        </gl-alert>
        <div class="row gl-display-flex gl-align-items-center">
          <gl-button-group class="col-md-5">
            <input
              name="service[vulnerabilities_issuetype]"
              type="hidden"
              :value="checkedIssueType.id || initialIssueTypeId"
            />
            <gl-dropdown
              class="gl-w-full"
              :disabled="!jiraIssueTypes.length"
              :loading="isLoadingJiraIssueTypes"
              :text="checkedIssueType.name || $options.i18n.issueTypeSelect.defaultText"
              data-qa-selector="service_jira_select_issue_type_dropdown"
            >
              <gl-dropdown-item
                v-for="jiraIssueType in jiraIssueTypes"
                :key="jiraIssueType.id"
                :is-checked="checkedIssueType.id === jiraIssueType.id"
                is-check-item
                data-qa-selector="service_jira_type"
                :data-qa-service-type="jiraIssueType.name"
                @click="selectedJiraIssueType = jiraIssueType"
              >
                {{ jiraIssueType.name }}
              </gl-dropdown-item>
            </gl-dropdown>
            <gl-button
              v-gl-tooltip.hover
              :title="$options.i18n.fetchIssueTypesButtonLabel"
              :aria-label="$options.i18n.fetchIssueTypesButtonLabel"
              :disabled="!projectKey"
              icon="retry"
              data-testid="fetch-issue-types"
              data-qa-selector="service_jira_issue_types_fetch_retry_button"
              @click="handleLoadJiraIssueTypesClick"
            />
          </gl-button-group>
          <p v-if="projectKeyWarning" class="gl-my-0">
            <gl-icon name="warning" class="gl-text-orange-500" />
            {{ projectKeyWarning }}
          </p>
        </div>
      </div>
    </template>
  </div>
</template>
