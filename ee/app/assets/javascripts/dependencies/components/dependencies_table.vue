<script>
import {
  GlBadge,
  GlIcon,
  GlButton,
  GlSkeletonLoader,
  GlTable,
  GlPopover,
  GlLink,
} from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { s__ } from '~/locale';
import DependencyLicenseLinks from './dependency_license_links.vue';
import DependencyLocation from './dependency_location.vue';
import DependencyVulnerabilities from './dependency_vulnerabilities.vue';

const tdClass = (defaultClasses = []) => (value, key, item) => {
  const classes = [...defaultClasses];

  // Don't draw a border between a row and its `row-details` slot
  // eslint-disable-next-line no-underscore-dangle
  if (item._showDetails) {
    classes.push('border-bottom-0');
  }

  return classes;
};

export default {
  name: 'DependenciesTable',
  components: {
    DependencyLicenseLinks,
    DependencyVulnerabilities,
    DependencyLocation,
    GlBadge,
    GlIcon,
    GlButton,
    GlSkeletonLoader,
    GlTable,
    GlPopover,
    GlLink,
  },
  props: {
    dependencies: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      localDependencies: this.transformDependenciesForUI(this.dependencies),
    };
  },
  computed: {
    anyDependencyHasVulnerabilities() {
      return this.localDependencies.some(({ vulnerabilities }) => vulnerabilities.length > 0);
    },
  },
  watch: {
    dependencies(dependencies) {
      this.localDependencies = this.transformDependenciesForUI(dependencies);
    },
  },
  methods: {
    // The GlTable component mutates the `_showDetails` property on items
    // passed to it in order to track the visibility of each row's `row-details`
    // slot. So, create a deep clone of them here to avoid mutating the
    // `dependencies` prop.
    // We also make sure that `vulnerabilities` is always defined to prevent rendering
    // errors when the user is allowe to see dependencies but not their vulnerabilities.
    transformDependenciesForUI(dependencies) {
      return dependencies.map(({ vulnerabilities, ...dep }) => ({
        ...cloneDeep(dep),
        vulnerabilities: vulnerabilities ? cloneDeep(vulnerabilities) : [],
      }));
    },
  },
  fields: [
    { key: 'component', label: s__('Dependencies|Component'), tdClass: tdClass() },
    { key: 'packager', label: s__('Dependencies|Packager'), tdClass: tdClass() },
    { key: 'location', label: s__('Dependencies|Location'), tdClass: tdClass(['gl-md-max-w-26']) },
    { key: 'license', label: s__('Dependencies|License'), tdClass: tdClass() },
    { key: 'isVulnerable', label: '', tdClass: tdClass(['gl-text-right']) },
  ],
  DEPENDENCIES_PER_PAGE: 20,
  DEPENDENCY_PATH_LINK:
    'https://docs.gitlab.com/ee/user/application_security/dependency_list/#dependency-paths',
  i18n: {
    tooltipText: s__(
      'Dependencies|The component dependency path is based on the lock file. There may be several paths. In these cases, the longest path is displayed.',
    ),
    tooltipMoreText: s__('Dependencies|Learn more about dependency paths'),
  },
};
</script>

<template>
  <gl-table
    :fields="$options.fields"
    :items="localDependencies"
    :busy="isLoading"
    data-qa-selector="dependencies_table_content"
    details-td-class="pt-0"
    stacked="md"
  >
    <template #head(location)="data">
      {{ data.label }}
      <gl-icon id="location-info" name="information-o" class="gl-text-blue-600" />
      <gl-popover
        target="location-info"
        placement="top"
        :title="s__('Dependencies|Location and dependency path')"
      >
        {{ $options.i18n.tooltipText }}
        <div class="gl-mt-4">
          <gl-link
            :href="$options.DEPENDENCY_PATH_LINK"
            target="_blank"
            class="font-size-inherit"
            >{{ $options.i18n.tooltipMoreText }}</gl-link
          >
        </div>
      </gl-popover>
    </template>

    <!-- toggleDetails and detailsShowing are scoped slot props provided by
      GlTable; they mutate/read the item's _showDetails property, which GlTable
      uses to show/hide the row-details slot -->
    <template #cell(component)="{ item, toggleDetails, detailsShowing }">
      <gl-button
        v-if="anyDependencyHasVulnerabilities"
        class="d-none d-md-inline"
        :class="{ invisible: !item.vulnerabilities.length }"
        category="tertiary"
        size="small"
        :aria-label="s__('Dependencies|Toggle vulnerability list')"
        :icon="detailsShowing ? 'chevron-up' : 'chevron-down'"
        @click="toggleDetails"
      />
      <span class="bold">{{ item.name }}</span
      >&nbsp;{{ item.version }}
    </template>

    <template #cell(location)="{ item }">
      <dependency-location :location="item.location" />
    </template>

    <template #cell(license)="{ item }">
      <dependency-license-links :licenses="item.licenses" :title="item.name" />
    </template>

    <template #cell(isVulnerable)="{ item, toggleDetails }">
      <gl-badge
        v-if="item.vulnerabilities.length"
        variant="warning"
        href="#"
        @click.native="toggleDetails"
      >
        <gl-icon name="warning" class="gl-text-orange-500 mr-1" />
        {{
          n__(
            'Dependencies|%d vulnerability detected',
            'Dependencies|%d vulnerabilities detected',
            item.vulnerabilities.length,
          )
        }}
      </gl-badge>
    </template>

    <template #row-details="{ item }">
      <dependency-vulnerabilities class="ml-4" :vulnerabilities="item.vulnerabilities" />
    </template>

    <template #table-busy>
      <div class="mt-2">
        <gl-skeleton-loader v-for="n in $options.DEPENDENCIES_PER_PAGE" :key="n" :lines="1" />
      </div>
    </template>
  </gl-table>
</template>
