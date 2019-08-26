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
7
class Conjur::Command::Link < Conjur::Command
    require 'open-uri'
    desc "Link hosts and safes to apps"
    command :link do |link|
        link.desc "Link a safe to an app"
        link.command :safe do |safe|
          safe.desc "App name"
          safe.flag [:a, :app]

          safe.desc "Safe name"
          safe.flag [:s,:safe]

          safe.desc "Output policy yml rather than load policy"
          safe.switch [:y,:yaml]

          safe.action do |global_options,options,args|
            app_name = options[:app]
            safe_name = options[:safe]
            yaml = options[:yaml] || false
            
            namespace = get_namespace(true)
            policy_id = namespace
            filename = 'templates/link-safe.yml'

            safe_group = get_safe_group(namespace, safe_name)

            if safe_group == nil
              puts "ERROR: Safe group could not be found for safe #{safe_name}"
            else
              file = open(filename).read
              policy = file.gsub("{{ SAFE_NAME }}", safe_name).gsub("{{ APP_NAME }}", app_name)
              load_policy(policy_id, policy, yaml)
            end
          end
        end
        link.desc "Link all safes to an application"
        link.command :allsafes do |safe|
          safe.desc "App name"
          safe.flag [:a, :app]

          safe.desc "Output policy yml rather than load policy"
          safe.switch [:y,:yaml]

          safe.action do |global_options,options,args|
            app_name = options[:app]
            yaml = options[:yaml] || false
            
            namespace = get_namespace(true)
            policy_id = namespace
            filename = 'templates/link-safe.yml'
            file = open(filename).read
            policy = file.gsub("{{ APP_NAME }}", app_name)

            load_policy(policy_id, policy, yaml)
          end
        end
        link.desc "Link a host to an application"
        link.command :host do |host|

          host.desc "App name"
          host.flag [:a, :app]

          host.desc "Host ID"
          host.flag [:h,:host]
          
          host.desc "Output policy yml rather than load policy"
          host.switch [:y,:yaml]

          host.action do |global_options,options,args|
            app_name = options[:app]
            host_id = options[:host]
            yaml = options[:yaml] || false

            namespace = get_namespace(true)
            policy_id = namespace

            filename = 'templates/link-host.yml'
            # make sure the host exists in the namespace
            hosts=Conjur::Command.api.resources({kind: "host", search: "#{namespace}/#{host_id}"})

            if hosts.length < 1
              puts "ERROR: Host #{host_id} does not exists or you do not have permissions"
            elsif hosts.length == 1
              file = open(filename).read
              policy = file.gsub("{{ HOST_ID }}", host_id).gsub("{{ APP_NAME }}", app_name)
              load_policy(policy_id, policy, yaml)
            else
              puts "ERROR: More than one host with name '#{host_id}' found. #{hosts}"
            end
          end
        end
      end

      def self.get_safe_group(namespace, safe_name)
        safe_group = nil
        safe_group_id = "#{namespace}/safe_#{safe_name}"

        safe_groups=Conjur::Command.api.resources({kind: "group", search: safe_group_id})
        
        safe_groups.each do |safe|
          if safe.id.to_s.ends_with? "group:#{safe_group_id}"
            safe_group = safe_group_id
          end
        end
        safe_group
      end
    end
