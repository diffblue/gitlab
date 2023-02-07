<script>
import {
  GlAccordion,
  GlAccordionItem,
  GlAvatar,
  GlButton,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';
import EditProtectedEnvironmentRulesCard from './edit_protected_environment_rules_card.vue';

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlAvatar,
    GlButton,
    GlSprintf,
    EditProtectedEnvironmentRulesCard,
  },
  directives: {
    GlTooltip,
  },
  computed: {
    ...mapState(['loading', 'protectedEnvironments', 'usersForRules']),
  },
  mounted() {
    this.fetchProtectedEnvironments();
  },
  methods: {
    ...mapActions(['fetchProtectedEnvironments', 'deleteRule']),
    filterRules(env) {
      return env.deploy_access_levels.filter(({ _destroy: destroy = false }) => !destroy);
    },
    canDeleteRules(env) {
      return env.deploy_access_levels.length > 1;
    },
  },
  i18n: {
    title: s__(
      'ProtectedEnvironments|List of protected environments (%{protectedEnvironmentsCount})',
    ),
    deployersHeader: s__('ProtectedEnvironments|Allowed to deploy'),
    usersHeader: s__('ProtectedEnvironments|Users'),
    deleteButtonTitle: s__('ProtectedEnvironments|Delete deployment rule'),
  },
};
</script>
<template>
  <div data-testid="protected-environments-list">
    <h5>
      <gl-sprintf :message="$options.i18n.title">
        <template #protectedEnvironmentsCount>{{ protectedEnvironments.length }}</template>
      </gl-sprintf>
    </h5>
    <gl-accordion :header-level="6">
      <gl-accordion-item
        v-for="environment in protectedEnvironments"
        :key="environment.name"
        :title="environment.name"
      >
        <edit-protected-environment-rules-card
          :loading="loading"
          :environment="environment"
          rule-key="deploy_access_levels"
          :data-testid="`protected-environment-${environment.name}-deployers`"
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
