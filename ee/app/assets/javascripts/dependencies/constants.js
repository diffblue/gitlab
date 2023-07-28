import { s__ } from '~/locale';

export const NAMESPACE_PROJECT = 'project';
export const NAMESPACE_GROUP = 'group';

export const DEPENDENCIES_TABLE_I18N = {
  component: s__('Dependencies|Component'),
  packager: s__('Dependencies|Packager'),
  location: s__('Dependencies|Location'),
  unknown: s__('Dependencies|unknown'),
  license: s__('Dependencies|License'),
  projects: s__('Dependencies|Projects'),
  tooltipText: s__(
    'Dependencies|The component dependency path is based on the lock file. There may be several paths. In these cases, the longest path is displayed.',
  ),
  tooltipMoreText: s__('Dependencies|Learn more about dependency paths'),
  locationDependencyTitle: s__('Dependencies|Location and dependency path'),
  toggleVulnerabilityList: s__('Dependencies|Toggle vulnerability list'),
};
