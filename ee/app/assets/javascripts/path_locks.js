import $ from 'jquery';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { sprintf, __ } from '~/locale';

export default function initPathLocks(url, path) {
  $('a.path-lock').on('click', async (e) => {
    e.preventDefault();

    const { dataset } = e.target;
    const message =
      dataset.state === 'lock'
        ? __('Are you sure you want to lock %{path}?')
        : __('Are you sure you want to unlock %{path}?');

    const confirmed = await confirmAction(sprintf(message, { path }));
    if (!confirmed) {
      return;
    }

    axios
      .post(url, {
        path,
      })
      .then(() => {
        window.location.reload();
      })
      .catch(() =>
        createAlert({
          message: __('An error occurred while initializing path locks'),
        }),
      );
  });
}
