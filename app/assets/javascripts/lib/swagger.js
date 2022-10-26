import { SwaggerUIBundle } from 'swagger-ui-dist';
import { safeLoad } from 'js-yaml';

const renderSwaggerUI = (yamlSpec) => {
  /* SwaggerUIBundle accepts openapi definition
   * in only JSON format, so we convert the YAML
   * config to JSON. It also keeps JSON input intact.
   */
  const spec = safeLoad(yamlSpec, { json: true });

  Promise.all([import(/* webpackChunkName: 'openapi' */ 'swagger-ui-dist/swagger-ui.css')])
    .then(() => {
      SwaggerUIBundle({
        spec,
        dom_id: '#swagger-ui',
        deepLinking: true,
        displayOperationId: true,
      });
    })
    .catch((error) => {
      throw error;
    });
};

const addInitHook = () => {
  window.addEventListener(
    'message',
    (event) => {
      if (event.origin !== window.location.origin) {
        return;
      }
      renderSwaggerUI(event.data);
    },
    false,
  );
};

addInitHook();
export default {};
