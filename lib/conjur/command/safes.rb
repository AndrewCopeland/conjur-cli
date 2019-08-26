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

class Conjur::Command::Safe < Conjur::Command
    desc "Manage cyberark safes within conjur"
    command :safe do |safe|
      safe.desc "Manage safe admins"
      safe.command :admin do |admin|
        admin.desc "Manage admins to cyberark safes. Admins have the ability to give others rights to the safe"

        admin.command :add do |add|
          add.desc "User to be added to the safe as an admin"
          add.flag [:u,:user]

          add.desc "Safe in which user will be added to as an admin"
          add.flag [:s,:safe]

          add.action do |global_options,options,args|
            username = options[:user]
            safe = options[:safe]

            filename = 'integrations/safes-admin-add.yml'
            require 'open-uri'
            file = open(filename).read
            admin_group = "#{safe}-admins"
            policy = file.gsub("{{ GROUP_NAME }}", admin_group).gsub("{{ USERNAME }}", username)
            res=Conjur::Command.api.resources({kind: "policy", search: "/" + safe + "/delegation"})

            if res.length < 1
              puts "Safe #{safe} does not exists or you do not have permissions"
            elsif res.length == 1
              id = res[0].id.to_s
              id = id.split(":", 3)[2]
              policy_id = id.sub! "/#{safe}/delegation", ""
              method = Conjur::API::POLICY_METHOD_POST
              result = api.load_policy policy_id, policy, method: method
              puts "Loaded policy '#{policy_id}'"
              puts JSON.pretty_generate(result)
            else
              puts "More than one safe was returned with name #{safe}"
            end
          end
        end
      end
      safe.desc "List safes in conjur"
      safe.command :list do |list|
        list.desc "List cyberark safes within conjur"
        list.action do |global_options,options,args|
          safes=Conjur::Command.api.resources({kind: "group", search: "/delegation/consumers"})
          safes.each do |safe|
            safe_name = safe.id.to_s.split("/")[2]
            puts "#{safe_name}"
          end
        end
      end
    end
  end