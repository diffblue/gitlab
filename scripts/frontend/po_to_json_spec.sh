#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/../.." &> /dev/null && pwd )
cd "$ROOT_DIR" || exit 1

touch locale/gitlab.pot
rm -rf tmp/po_json_before tmp/po_json_after

echo "Generate locale / app.js files the _old_ way"
rm -f app/assets/javascripts/locale/**/app.js
time bundle exec rake gettext:po_to_json
cp -r app/assets/javascripts/locale tmp/po_json_before

echo "Generate locale / app.js files the _new_ way"
rm -f app/assets/javascripts/locale/**/app.js
time node scripts/frontend/po_to_json.js
cp -r app/assets/javascripts/locale tmp/po_json_after

rm -f app/assets/javascripts/locale/**/app.js
echo "Running specs"
TEST_PO_FILE_EQUIVALENCE=true yarn run jest:integration spec/frontend_integration/po_to_json_spec.js --runInBand
