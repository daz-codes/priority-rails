# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/request.js", to: "https://ga.jspm.io/npm:@rails/request.js@0.0.8/src/index.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "sortablejs" # @1.15.6
pin "helium", to: "https://esm.sh/@daz4126/helium@1.0.0-beta.5/csp"
pin_all_from "app/javascript/helium_modules", under: "modules"
pin "lexxy", to: "lexxy.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
