<script>
import {
  GlAccordion,
  GlAccordionItem,
  GlAvatar,
  GlButton,
  GlFormGroup,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { s__, __ } from '~/locale';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { ACCESS_LEVELS } from './constants';
import EditProtectedEnvironmentRulesCard from './edit_protected_environment_rules_card.vue';
import AddRuleModal from './add_rule_modal.vue';

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlAvatar,
    GlButton,
    GlFormGroup,
    GlSprintf,
    AccessDropdown,
    EditProtectedEnvironmentRulesCard,
    AddRuleModal,
  },
  directives: {
    GlTooltip,
  },
  inject: { accessLevelsData: { default: [] } },
  data() {
    return { isAddingRule: false, addingEnvironment: null };
  },
  computed: {
    ...mapState(['loading', 'protectedEnvironments', 'usersForRules']),
  },
  mounted() {
    this.fetchProtectedEnvironments();
  },
  methods: {
    ...mapActions(['fetchProtectedEnvironments', 'deleteRule', 'setRule', 'saveRule']),
    filterRules(env) {
      return env.deploy_access_levels.filter(({ _destroy: destroy = false }) => !destroy);
    },
    canDeleteRules(env) {
      return env.deploy_access_levels.length > 1;
    },
    addRule(env) {
      this.addingEnvironment = env;
      this.isAddingRule = true;
    },
  },
  i18n: {
    title: s__(
      'ProtectedEnvironments|List of protected environments (%{protectedEnvironmentsCount})',
    ),
    deployersHeader: s__('ProtectedEnvironments|Allowed to deploy'),
    usersHeader: s__('ProtectedEnvironments|Users'),
    addButtonText: s__('ProtectedEnvironments|Add deployment rules'),
    deleteButtonTitle: s__('ProtectedEnvironments|Delete deployment rule'),
    addModalTitle: s__('ProtectedEnvironments|Create deployment rule'),
    addModalText: __('Set a group, access level or users who are required to deploy.'),
    addDeployerLabel: s__('ProtectedEnvironments|Allowed to deploy'),
  },
  ACCESS_LEVELS,
};
</script>
<template>
  <div data-testid="protected-environments-list">
    <h5>
      <gl-sprintf :message="$options.i18n.title">
        <template #protectedEnvironmentsCount>{{ protectedEnvironments.length }}</template>
      </gl-sprintf>
    </h5>
    <add-rule-modal
      v-model="isAddingRule"
      :title="$options.i18n.addModalTitle"
      @saveRule="saveRule(addingEnvironment)"
    >
      <template #add-rule-form>
        <p>{{ $options.i18n.addModalText }}</p>
        <gl-form-group :label="$options.i18n.addDeployerLabel" label-for="create-deployer-dropdown">
          <access-dropdown
            id="create-deployer-dropdown"
            class="gl-w-30p"
            :access-levels-data="accessLevelsData"
            :access-level="$options.ACCESS_LEVELS.DEPLOY"
            @hidden="setRule({ environment: addingEnvironment, newRules: $event })"
          />
        </gl-form-group>
      </template>
    </add-rule-modal>
    <gl-accordion :header-level="6">
      <gl-accordion-item
        v-for="environment in protectedEnvironments"
        :key="environment.name"
        :title="environment.name"
      >
        <edit-protected-environment-rules-card
          :loading="loading"
          :add-button-text="$options.i18n.addButtonText"
          :environment="environment"
          rule-key="deploy_access_levels"
          :data-testid="`protected-environment-${environment.name}-deployers`"
          @addRule="addRule"
        >
          <template #card-header>
            <span class="gl-w-30p gl-font-weight-bold">{{ $options.i18n.deployersHeader }}</span>
            <span class="gl-font-weight-bold">{{ $options.i18n.usersHeader }}</span>
          </template>
          <template #rule="{ rule }">
            <span class="gl-w-30p" data-testid="rule-description">
              {{ rule.access_level_description }}
            </span>

            <gl-avatar
              v-for="user in usersForRules[rule.id]"
              :key="user.id"
              v-gl-tooltip
              :src="user.avatar_url"
              :title="user.name"
              :size="24"
              class="gl-mr-2"
            />

            <gl-button
              v-if="canDeleteRules(environment)"
              category="secondary"
              variant="danger"
              icon="remove"
              :loading="loading"
              :title="$options.i18n.deleteButtonTitle"
              :aria-label="$options.i18n.deleteButtonTitle"
              class="gl-ml-auto"
              @click="deleteRule({ environment, rule })"
            />
          </template>
        </edit-protected-environment-rules-card>
      </gl-accordion-item>
    </gl-accordion>
  </div>
</template>
