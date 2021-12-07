import $ from 'jquery';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

const selectElement = document.getElementById('country_select');

if (selectElement?.dataset) {
  const { countriesEndPoint, selectedOption } = selectElement.dataset;

  axios
    .get(countriesEndPoint)
    .then(({ data }) => {
      // fill #country_select element with array of <option>s
      data.forEach(([name, code]) => {
        const option = document.createElement('option');
        option.value = code;
        option.text = name;

        selectElement.appendChild(option);
      });
      $(selectElement).val(selectedOption).trigger('change.select2');
    })
    .catch(() =>
      createFlash({
        message: __('Error loading countries data.'),
      }),
    );
}
