<script>
import { GlAlert, GlFormGroup, GlFormSelect, GlFormInput, GlSprintf, GlLink } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapState, mapGetters, mapActions } from 'vuex';
import { QSR_RECONCILIATION_PATH, STEP_SUBSCRIPTION_DETAILS } from 'ee/subscriptions/constants';
import { NEW_GROUP } from 'ee/subscriptions/new/constants';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { sprintf, s__, __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import Tracking from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlAlert,
    GlFormGroup,
    GlFormSelect,
    GlFormInput,
    GlSprintf,
    GlLink,
    Step,
  },
  directives: {
    autofocusonshow,
  },
  mixins: [Tracking.mixin()],
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
      'isGroupSelected',
      'selectedGroupUsers',
      'selectedGroupName',
    ]),
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
      return this.numberOfUsers >= this.selectedGroupUsers;
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
  methods: {
    ...mapActions([
      'updateSelectedPlan',
      'updateSelectedGroup',
      'toggleIsSetupForCompany',
      'updateNumberOfUsers',
      'updateOrganizationName',
    ]),
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
          v-autofocusonshow
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
          :label="$options.i18n.numberOfUsersLabel"
          label-size="sm"
          class="number gl-mb-0"
        >
          <gl-form-input
            ref="number-of-users"
            v-model.number="numberOfUsersModel"
            type="number"
            :min="selectedGroupUsers"
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
        class="gl-mt-5 gl-mb-6"
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
      <strong ref="summary-line-1">
        {{ selectedPlanTextLine }}
      </strong>
      <div v-if="isSetupForCompany" ref="summary-line-2">
        {{ $options.i18n.group }}: {{ organizationName || selectedGroupName }}
      </div>
      <div ref="summary-line-3">{{ $options.i18n.users }}: {{ numberOfUsers }}</div>
    </template>
  </step>
</template>
