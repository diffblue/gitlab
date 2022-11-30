import $ from 'jquery';
import { escape } from 'lodash';
import Api from '~/api';
import { sanitizeItem } from '~/frequent_items/utils';
import { loadCSSFile } from '~/lib/utils/css_utils';
import { sprintf, __ } from '~/locale';

const formatResult = (selectedItem) => {
  if (selectedItem.path_with_namespace) {
    return `<div class='project-result'> <div class='project-name'>${escape(
      selectedItem.name,
    )}</div> <div class='project-path'>${selectedItem.path_with_namespace}</div> </div>`;
  } else if (selectedItem.path) {
    return `<div class='group-result'> <div class='group-name'>${escape(
      selectedItem.name,
    )}</div> <div class='group-path'>${selectedItem.path}</div> </div>`;
  }
  return `<div class='group-result'> <div class='group-name'>${__(
    'All',
  )}</div> <div class='group-path'>${__('All groups and projects')}</div> </div>`;
};

const formatSelection = (selectedItem) => {
  if (selectedItem.path_with_namespace) {
    return sprintf(__('Project: %{name}'), { name: selectedItem.name });
  } else if (selectedItem.path) {
    return sprintf(__('Group: %{name}'), { name: selectedItem.name });
  }
  return __('All groups and projects');
};

const QueryAdmin = (query) => {
  const groupsFetch = Api.groups(query.term, {});
  const projectsFetch = Api.projects(query.term, {
    order_by: 'id',
    membership: false,
  });
  return Promise.all([projectsFetch, groupsFetch]).then(([projects, groups]) => {
    const all = {
      id: 'all',
    };
    const data = [all].concat(groups, projects.data).map(sanitizeItem);
    return query.callback({
      results: data,
    });
  });
};

const AdminEmailSelect = () => {
  loadCSSFile(gon.select2_css_path)
    .then(() => {
      $('.ajax-admin-email-select').each((i, select) =>
        $(select).select2({
          placeholder: __('Select group or project'),
          multiple: $(select).hasClass('multiselect'),
          minimumInputLength: 0,
          query(query) {
            QueryAdmin(query);
          },
          id(object) {
            if (object.path_with_namespace) {
              return `project-${object.id}`;
            } else if (object.path) {
              return `group-${object.id}`;
            }
            return 'all';
          },
          formatResult(...args) {
            return formatResult(...args);
          },
          formatSelection(...args) {
            return formatSelection(...args);
          },
          dropdownCssClass: 'ajax-admin-email-dropdown',
          escapeMarkup(m) {
            return m;
          },
        }),
      );
    })
    .catch(() => {});
};

export default () =>
  import(/* webpackChunkName: 'select2' */ 'select2/select2')
    .then(AdminEmailSelect)
    .catch(() => {});
