# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "sortablejs" # @1.15.6
# @daz4126/helium 1.0.0-rc.6, CSP + Turbo build (dist/helium-csp-turbo.min.js)
pin "helium", to: "helium.js"
pin_all_from "app/javascript/behaviors", under: "behaviors"
pin_all_from "app/javascript/lib", under: "lib"
pin "lexxy", to: "lexxy.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
