import $ from 'jquery';

const namespaceId = $('#namespace_id');
const newGroupName = $('#group_name');

namespaceId.on('change', () => {
  const enableNewGroupName = namespaceId.val() === '0';

  newGroupName
    .toggleClass('hidden', !enableNewGroupName)
    .find('input')
    .prop('required', enableNewGroupName);
});

namespaceId.trigger('change');
