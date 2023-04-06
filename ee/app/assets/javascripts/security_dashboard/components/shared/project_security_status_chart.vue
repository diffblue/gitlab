<script>
import { GlLink, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { keyBy } from 'lodash';
import {
  severityGroupTypes,
  severityLevels,
  severityLevelsTranslations,
  SEVERITY_LEVELS_ORDERED_BY_SEVERITY,
  SEVERITY_GROUPS,
} from 'ee/security_dashboard/constants';
import { Accordion, AccordionItem } from 'ee/vue_shared/components/accordion';
import { s__, n__, sprintf } from '~/locale';
import SecurityDashboardCard from './security_dashboard_card.vue';

export default {
  css: {
    severityGroups: {
      [severityGroupTypes.F]: 'gl-text-red-900',
      [severityGroupTypes.D]: 'gl-text-red-700',
      [severityGroupTypes.C]: 'gl-text-orange-600',
      [severityGroupTypes.B]: 'gl-text-orange-400',
      [severityGroupTypes.A]: 'gl-text-green-500',
    },
    severityLevels: {
      [severityLevels.CRITICAL]: 'gl-text-red-900',
      [severityLevels.HIGH]: 'gl-text-red-700',
      [severityLevels.UNKNOWN]: 'gl-text-gray-300',
      [severityLevels.MEDIUM]: 'gl-text-orange-600',
      [severityLevels.LOW]: 'gl-text-orange-500',
      [severityLevels.NONE]: 'gl-text-green-500',
    },
  },
  accordionItemsContentMaxHeight: '445px',
  components: { SecurityDashboardCard, Accordion, AccordionItem, GlLink, GlIcon },
  directives: {
    'gl-tooltip': GlTooltipDirective,
  },
  inject: ['groupFullPath'],
  props: {
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    query: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      vulnerabilityGrades: {},
      errorLoadingVulnerabilitiesGrades: false,
    };
  },
  apollo: {
    vulnerabilityGrades: {
      query() {
        return this.query;
      },
      variables() {
        return {
          fullPath: this.groupFullPath,
        };
      },
      update(results) {
        const { vulnerabilityGrades } = this.groupFullPath
          ? results.group
          : results.instanceSecurityDashboard;

        // This will convert the results array into an object where the key is the grade property:
        // {
        //    A: { grade: 'A', count: 1, projects: { nodes: [ ... ] },
        //    B: { grade: 'B', count: 2, projects: { nodes: [ ... ] }
        // }
        return keyBy(vulnerabilityGrades, 'grade');
      },
      error() {
        this.errorLoadingVulnerabilitiesGrades = true;
      },
    },
  },
  computed: {
    isLoadingGrades() {
      return this.$apollo.queries.vulnerabilityGrades.loading;
    },
    severityGroups() {
      return SEVERITY_GROUPS.map((group) => ({
        ...group,
        count: this.vulnerabilityGrades[group.type]?.count || 0,
        projects: this.findProjectsForGroup(group),
      }));
    },
  },
  methods: {
    findProjectsForGroup(group) {
      if (!this.vulnerabilityGrades[group.type]) {
        return [];
      }

      return this.vulnerabilityGrades[group.type].projects.nodes.map((project) => ({
        ...project,
        mostSevereVulnerability: this.findMostSevereVulnerabilityForGroup(project, group),
      }));
    },
    findMostSevereVulnerabilityForGroup(project, group) {
      const mostSevereVulnerability = {};

      SEVERITY_LEVELS_ORDERED_BY_SEVERITY.some((level) => {
        if (!group.severityLevels.includes(level)) {
          return false;
        }

        const hasVulnerabilityForThisLevel = project.vulnerabilitySeveritiesCount?.[level] > 0;

        if (hasVulnerabilityForThisLevel) {
          mostSevereVulnerability.level = level;
          mostSevereVulnerability.count = project.vulnerabilitySeveritiesCount[level];
        }

        return hasVulnerabilityForThisLevel;
      });

      return mostSevereVulnerability;
    },
    shouldAccordionItemBeDisabled({ projects }) {
      return projects?.length < 1;
    },
    cssForSeverityGroup({ type }) {
      return this.$options.css.severityGroups[type];
    },
    cssForMostSevereVulnerability({ level }) {
      return this.$options.css.severityLevels[level] || [];
    },
    severityText(severityLevel) {
      return severityLevelsTranslations[severityLevel];
    },
    getProjectCountString({ count, projects }) {
      // The backend only returns the first 100 projects, so if the project count is greater than
      // the projects array length, we'll show "100+ projects". Note that n__ only works with
      // numbers, so we can't pass it a string like "100+", which is why we need the ternary to
      // use a different string for "100+ projects". This is temporary code until this backend issue
      // is complete, and we can show the actual counts and page through the projects:
      // https://gitlab.com/gitlab-org/gitlab/-/issues/350110
      return count > projects.length
        ? sprintf(s__('SecurityReports|%{count}+ projects'), { count: projects.length })
        : n__('%d project', '%d projects', count);
    },
  },
};
</script>

<template>
  <security-dashboard-card :is-loading="isLoadingGrades">
    <template #title>
      {{ __('Project security status') }}
      <gl-link
        v-if="helpPagePath"
        :href="helpPagePath"
        :aria-label="__('Project security status help page')"
        target="_blank"
        ><gl-icon name="question-o"
      /></gl-link>
    </template>
    <template v-if="!isLoadingGrades" #help-text>
      {{ __('Projects are graded based on the highest severity vulnerability present') }}
    </template>

    <accordion
      class="gl-px-5 gl-display-flex gl-flex-grow-1 gl-border-t-1 gl-border-t-solid gl-border-t-gray-100"
      :list-classes="['gl-display-flex', 'gl-flex-grow-1']"
    >
      <template #default="{ accordionId }">
        <accordion-item
          v-for="severityGroup in severityGroups"
          :ref="`accordionItem${severityGroup.type}`"
          :key="severityGroup.type"
          :data-qa-selector="`severity_accordion_item_${severityGroup.type}`"
          :accordion-id="accordionId"
          :disabled="shouldAccordionItemBeDisabled(severityGroup)"
          :max-height="$options.accordionItemsContentMaxHeight"
          class="gl-display-flex gl-flex-grow-1 gl-flex-direction-column gl-justify-content-center"
        >
          <template #title="{ isExpanded, isDisabled }">
            <h5
              class="gl-display-flex gl-align-items-center gl-font-weight-normal gl-p-0 gl-m-0"
              data-testid="vulnerability-severity-groups"
            >
              <span
                v-gl-tooltip
                :title="severityGroup.description"
                class="gl-font-weight-bold gl-mr-5 gl-font-lg"
                :class="cssForSeverityGroup(severityGroup)"
              >
                {{ severityGroup.type }}
              </span>
              <span :class="{ 'gl-font-weight-bold': isExpanded, 'gl-text-gray-500': isDisabled }">
                {{ getProjectCountString(severityGroup) }}
              </span>
            </h5>
          </template>
          <template #sub-title>
            <p class="gl-m-0 gl-ml-7 gl-pb-2 gl-text-gray-500">{{ severityGroup.warning }}</p>
          </template>
          <div class="gl-ml-7 gl-pb-3">
            <ul class="list-unstyled gl-py-2">
              <li v-for="project in severityGroup.projects" :key="project.id" class="gl-py-3">
                <gl-link
                  target="_blank"
                  :href="project.securityDashboardPath"
                  data-qa-selector="project_name_text"
                  >{{ project.nameWithNamespace }}</gl-link
                >
                <span
                  v-if="project.mostSevereVulnerability"
                  ref="mostSevereCount"
                  class="gl-display-block text-lowercase"
                  :class="cssForMostSevereVulnerability(project.mostSevereVulnerability)"
                  >{{ project.mostSevereVulnerability.count }}
                  {{ severityText(project.mostSevereVulnerability.level) }}
                </span>
              </li>
            </ul>
          </div>
        </accordion-item>
      </template>
    </accordion>
  </security-dashboard-card>
</template>
