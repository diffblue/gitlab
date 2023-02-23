<script>
import {
  GlAlert,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import { QSR_RECONCILIATION_PATH, STEP_SUBSCRIPTION_DETAILS } from 'ee/subscriptions/constants';
import { PurchaseEvent, NEW_GROUP } from 'ee/subscriptions/new/constants';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { __, s__, sprintf } from '~/locale';
import autoFocusOnShow from '~/vue_shared/directives/autofocusonshow';
import Tracking from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';
import getBillableMembersCountQuery from 'ee/subscriptions/graphql/queries/billable_members_count.query.graphql';

export default {
  components: {
    GlAlert,
    GlFormGroup,
    GlFormSelect,
    GlFormInput,
    GlSprintf,
    GlLink,
    GlLoadingIcon,
    Step,
  },
  directives: {
    autoFocusOnShow,
  },
  mixins: [Tracking.mixin()],
  apollo: {
    billableData: {
      query: getBillableMembersCountQuery,
      variables() {
        return {
          fullPath: this.selectedGroupFullPath,
          requestedHostedPlan: this.selectedPlanDetails.code,
        };
      },
      update(data) {
        this.resetError();

        return {
          minimumSeats: data.group.billableMembersCount || 1,
          enforceFreeUserCap: data.group.enforceFreeUserCap,
        };
      },
      skip() {
        return this.shouldSkipQuery;
      },
      error(error) {
        this.handleError(error);
      },
    },
  },
  data() {
    return {
      billableData: { minimumSeats: 1, enforceFreeUserCap: false },
      hasError: false,
    };
  },
  computed: {
    ...mapState([
      'availablePlans',
      'selectedPlan',
      'isNewUser',
      'groupData',
      'selectedGroup',
      'isSetupForCompany',
      'organizationName',
      'numberOfUsers',
    ]),
    ...mapGetters([
      'selectedPlanText',
      'selectedPlanDetails',
      'selectedGroupId',
      'selectedGroupData',
      'isGroupSelected',
      'selectedGroupName',
      'isSelectedGroupPresent',
    ]),
    isLoading() {
      return this.$apollo.queries.billableData.loading;
    },
    selectedPlanModel: {
      get() {
        return this.selectedPlan;
      },
      set(selectedPlan) {
        this.updateSelectedPlan(selectedPlan);
      },
    },
    selectedGroupModel: {
      get() {
        return this.selectedGroup;
      },
      set(selectedGroup) {
        this.updateSelectedGroup(selectedGroup);
      },
    },
    numberOfUsersModel: {
      get() {
        return this.numberOfUsers;
      },
      set(number) {
        this.updateNumberOfUsers(number);
      },
    },
    organizationNameModel: {
      get() {
        return this.organizationName;
      },
      set(organizationName) {
        this.updateOrganizationName(organizationName);
      },
    },
    selectedPlanTextLine() {
      return sprintf(this.$options.i18n.selectedPlan, { selectedPlanText: this.selectedPlanText });
    },
    selectedGroupFullPath() {
      return this.selectedGroupData?.fullPath;
    },
    shouldSkipQuery() {
      return (
        !this.selectedGroupFullPath || !this.hasSelectedPlan || this.shouldDisableNumberOfUsers
      );
    },
    numberOfUsersLabelDescription() {
      if (this.shouldSkipQuery || this.hasError) {
        return null;
      }

      const translation = this.billableData.enforceFreeUserCap
        ? this.$options.i18n.numberOfUsersLabelDescriptionFreeUserCap
        : this.$options.i18n.numberOfUsersLabelDescription;

      return sprintf(translation, {
        minimumNumberOfUsers: this.billableData.minimumSeats,
      });
    },
    hasAtLeastOneUser() {
      return this.numberOfUsers > 0;
    },
    hasSelectedPlan() {
      return !isEmpty(this.selectedPlan);
    },
    hasOrganizationName() {
      return !isEmpty(this.organizationName);
    },
    hasRequisitesForCompany() {
      if (this.isSetupForCompany) {
        return this.hasOrganizationName || this.isGroupSelected;
      }
      return true;
    },
    isSelectedUsersEqualOrGreaterThanGroupUsers() {
      return this.numberOfUsers >= this.billableData.minimumSeats;
    },
    isValid() {
      return (
        this.hasSelectedPlan &&
        this.hasAtLeastOneUser &&
        this.isSelectedUsersEqualOrGreaterThanGroupUsers &&
        this.hasRequisitesForCompany
      );
    },
    isShowingGroupSelector() {
      return !this.isNewUser && this.groupData.length;
    },
    isShowingNameOfCompanyInput() {
      return this.isSetupForCompany && (!this.groupData.length || this.selectedGroup === NEW_GROUP);
    },
    groupOptionsWithDefault() {
      return [
        {
          text: this.$options.i18n.groupSelectPrompt,
          value: null,
        },
        ...this.groupData,
        {
          text: this.$options.i18n.groupSelectCreateNewOption,
          value: NEW_GROUP,
        },
      ];
    },
    groupSelectDescription() {
      return this.selectedGroup === NEW_GROUP
        ? this.$options.i18n.createNewGroupDescription
        : this.$options.i18n.selectedGroupDescription;
    },
    shouldDisableNumberOfUsers() {
      return this.isNewUser && !this.isSetupForCompany;
    },
  },
  watch: {
    billableData: {
      deep: true,
      handler(data) {
        this.updateNumberOfUsers(data.minimumSeats);
      },
    },
    isSelectedGroupPresent(isSelectedGroupPresent) {
      if (!isSelectedGroupPresent) {
        this.billableData.minimumSeats = 1;
      }
    },
  },
  methods: {
    ...mapActions([
      'updateSelectedPlan',
      'updateSelectedGroup',
      'toggleIsSetupForCompany',
      'updateNumberOfUsers',
      'updateOrganizationName',
    ]),
    handleError(error) {
      this.hasError = true;
      this.$emit(PurchaseEvent.ERROR, error);
    },
    resetError() {
      this.$emit(PurchaseEvent.ERROR_RESET);
      this.hasError = false;
    },
    trackStepTransition() {
      this.track('click_button', {
        label: 'update_plan_type',
        property: this.selectedPlanDetails.code,
      });
      this.track('click_button', { label: 'update_group', property: this.selectedGroupId });
      this.track('click_button', { label: 'update_seat_count', property: this.numberOfUsers });
      this.track('click_button', { label: 'continue_billing' });
    },
    trackStepEdit() {
      this.track('click_button', {
        label: 'edit',
        property: STEP_SUBSCRIPTION_DETAILS,
      });
    },
  },
  i18n: {
    stepTitle: s__('Checkout|Subscription details'),
    nextStepButtonText: s__('Checkout|Continue to billing'),
    selectedPlanLabel: s__('Checkout|GitLab plan'),
    selectedGroupLabel: s__('Checkout|GitLab group'),
    groupSelectPrompt: s__('Checkout|Select'),
    groupSelectCreateNewOption: s__('Checkout|Create a new group'),
    selectedGroupDescription: s__('Checkout|Your subscription will be applied to this group'),
    createNewGroupDescription: s__("Checkout|You'll create your new group after checkout"),
    organizationNameLabel: s__('Checkout|Name of company or organization using GitLab'),
    numberOfUsersLabel: s__('Checkout|Number of users'),
    numberOfUsersLabelDescription: s__(
      'Checkout|Must be %{minimumNumberOfUsers} (your seats in use) or more.',
    ),
    numberOfUsersLabelDescriptionFreeUserCap: s__(
      'Checkout|Must be %{minimumNumberOfUsers} (your seats in use, plus all over limit members) or more. To buy fewer seats, remove members from the group.',
    ),
    loadingText: s__('Checkout|Calculating your subscription...'),
    needMoreUsersLink: s__('Checkout|Need more users? Purchase GitLab for your %{company}.'),
    companyOrTeam: s__('Checkout|company or team'),
    selectedPlan: s__('Checkout|%{selectedPlanText} plan'),
    group: s__('Checkout|Group'),
    users: s__('Checkout|Users'),
    qsrOverageMessage: __(
      'You are billed if you exceed this number. %{qsrOverageLinkStart}How does billing work?%{qsrOverageLinkEnd}',
    ),
  },
  stepId: STEP_SUBSCRIPTION_DETAILS,
  qsrReconciliationLink: helpPagePath(QSR_RECONCILIATION_PATH),
};
</script>
<template>
  <step
    v-if="isLoading"
    :step-id="$options.stepId"
    :title="$options.i18n.stepTitle"
    :is-valid="false"
  >
    <template #body>
      <div
        data-testid="subscription-loading-container"
        class="gl-display-flex gl-h-200! gl-justify-content-center gl-align-items-center gl-flex-direction-column"
      >
        <gl-loading-icon v-if="true" size="lg" />
        <span>{{ $options.i18n.loadingText }}</span>
      </div>
    </template>
  </step>
  <step
    v-else
    :step-id="$options.stepId"
    :title="$options.i18n.stepTitle"
    :is-valid="isValid"
    :next-step-button-text="$options.i18n.nextStepButtonText"
    @nextStep="trackStepTransition"
    @stepEdit="trackStepEdit"
  >
    <template #body>
      <gl-form-group :label="$options.i18n.selectedPlanLabel" label-size="sm" class="mb-3">
        <gl-form-select
          v-model="selectedPlanModel"
          v-auto-focus-on-show
          :options="availablePlans"
          data-qa-selector="plan_name"
        />
      </gl-form-group>
      <gl-form-group
        v-if="isShowingGroupSelector"
        :label="$options.i18n.selectedGroupLabel"
        :description="groupSelectDescription"
        label-size="sm"
        class="mb-3"
      >
        <gl-form-select
          ref="group-select"
          v-model="selectedGroupModel"
          :options="groupOptionsWithDefault"
          data-qa-selector="group_name"
        />
      </gl-form-group>
      <gl-form-group
        v-if="isShowingNameOfCompanyInput"
        :label="$options.i18n.organizationNameLabel"
        label-size="sm"
        class="mb-3"
      >
        <gl-form-input ref="organization-name" v-model="organizationNameModel" type="text" />
      </gl-form-group>
      <div class="combined d-flex">
        <gl-form-group
          data-testid="number-of-users-field"
          :label="$options.i18n.numberOfUsersLabel"
          label-size="sm"
          class="gl-mb-0"
          :label-description="numberOfUsersLabelDescription"
        >
          <gl-form-input
            ref="number-of-users"
            v-model.number="numberOfUsersModel"
            class="number"
            type="number"
            :min="billableData.minimumSeats"
            :disabled="shouldDisableNumberOfUsers"
            data-qa-selector="number_of_users"
          />
        </gl-form-group>
        <gl-form-group
          v-if="shouldDisableNumberOfUsers"
          ref="company-link"
          class="label gl-mb-0 ml-3 align-self-end"
        >
          <gl-sprintf :message="$options.i18n.needMoreUsersLink">
            <template #company>
              <gl-link @click="toggleIsSetupForCompany">{{ $options.i18n.companyOrTeam }}</gl-link>
            </template>
          </gl-sprintf>
        </gl-form-group>
      </div>
      <gl-alert
        class="gl-my-5"
        :dismissible="false"
        variant="info"
        data-testid="qsr-overage-message"
      >
        <gl-sprintf :message="$options.i18n.qsrOverageMessage">
          <template #qsrOverageLink="{ content }">
            <gl-link :href="$options.qsrReconciliationLink" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>
    </template>
    <template #summary>
      <span ref="summary-line-1" class="gl-font-weight-bold">
        {{ selectedPlanTextLine }}
      </span>
      <div v-if="isSetupForCompany" ref="summary-line-2">
        {{ $options.i18n.group }}: {{ organizationName || selectedGroupName }}
      </div>
      <div ref="summary-line-3">{{ $options.i18n.users }}: {{ numberOfUsers }}</div>
    </template>
  </step>
</template>
