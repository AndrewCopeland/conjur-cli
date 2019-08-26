#
# Copyright (C) 2017 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class Conjur::Command::App < Conjur::Command
    desc "Create applications in your namespace"
    command :app do |apps|
      require 'open-uri'
      apps.desc "Create an application within a namespace"
      apps.command :create do |c|
        c.desc "Name of the app"
        c.flag [:a,:app]

        c.desc "Output policy yaml rather than loading"
        c.switch [:y,:yaml]
        
        c.action do |global_options,options,args|
          app_name = options[:app] || args.pop()
          yaml = options[:yaml] || false
          
          if app_name == nil
            exit_now! "app name was not provided"
          end

          policy_id = get_namespace(true)
          
          filename = 'templates/apps-create.yml'
          file = open(filename).read
          policy = file.gsub("{{ APP_NAME }}", app_name)

          load_policy(policy_id, policy, yaml)
        end
      end

      apps.desc "List applications"
      apps.command :list do |l|
        l.action do |global_options,options,args|
          resources = Conjur::Command.api.resources({kind: "policy", search: "csasaapp"})
          resources.each do |resource|
            kind, id = get_kind_and_id_from_args([resource.id.to_s])
            puts "#{id}"
          end
        end
      end
    end
  end