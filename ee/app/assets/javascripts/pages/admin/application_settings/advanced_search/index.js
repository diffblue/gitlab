import $ from 'jquery';
import {
  initNamespacesIndexingRestrictions,
  initProjectsIndexingRestrictions,
} from 'ee/admin/application_settings/advanced_search/init_indexing_restrictions';

const onLimitCheckboxChange = (checked, $limitByNamespaces, $limitByProjects) => {
  $limitByNamespaces.toggleClass('hidden', !checked);
  $limitByProjects.toggleClass('hidden', !checked);
};

// ElasticSearch
const $container = $('#js-elasticsearch-settings');

$container
  .find('.js-limit-checkbox')
  .on('change', (e) =>
    onLimitCheckboxChange(
      e.currentTarget.checked,
      $container.find('.js-limit-namespaces'),
      $container.find('.js-limit-projects'),
    ),
  );

initNamespacesIndexingRestrictions();
initProjectsIndexingRestrictions();
