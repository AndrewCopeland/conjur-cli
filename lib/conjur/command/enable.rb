    
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

class Conjur::Command::Enable < Conjur::Command
    require 'open-uri'
    desc "Enable integrations"
    command :enable do |enable|
        enable.desc "Enable jenkins integration"
        enable.command :jenkins do |c|
        c.arg_name "host"
        c.desc "Host name for policy"
        c.flag [:h,:host]
  
        c.action do |global_options,options,args|
          host = options[:host]
          policy_id = 'root'
          filename = 'integrations/jenkins.yml'
          file = open(filename).read
          policy = file.gsub("<HOST>", host)
          
          method = Conjur::API::POLICY_METHOD_POST
          result = api.load_policy policy_id, policy, method: method
          puts "Loaded policy '#{policy_id}'"
          puts JSON.pretty_generate(result)
        end
      end
      enable.desc "Enable an authenticator service"
      enable.command :authn do |a|
        a.desc "Enable an iam authenticator service"
        a.command :iam do |i|
            i.desc "Service ID"
            i.flag [:s,:serviceid]

            i.desc "Output policy yaml rather than loading"
            i.switch [:y,:yaml]
        
            i.action do |global_options,options,args|
                service_id = options[:serviceid] || args.pop()
                yaml = options[:yaml] || false
                
                if service_id == nil
                    exit_now! "authenticator service id was not provided"
                end
                policy_id = 'root'
                filename = 'integrations/enable-authn-iam.yml'
                file = open(filename).read
                policy = file.gsub("{{ SERVICE_ID }}", service_id)

                load_policy(policy_id, policy, yaml)
            end
        end
        a.desc "Enable a kubernetes authenticator service"
        a.command :k8s do |k|
            k.desc "Service ID"
            k.flag [:s,:serviceid]

            k.desc "Output policy yaml rather than loading"
            k.switch [:y,:yaml]
        
            k.action do |global_options,options,args|
                service_id = options[:serviceid] || args.pop()
                yaml = options[:yaml] || false
                
                if service_id == nil
                    exit_now! "authenticator service id was not provided"
                end
                
                policy_id = 'root'
                filename = 'integrations/enable-authn-k8s.yml'
                file = open(filename).read
                policy = file.gsub("{{ SERVICE_ID }}", service_id)

                load_policy(policy_id, policy, yaml)
            end
        end
    end
      
      enable.desc "Enable ansible integration"
      enable.command :ansible do |c|
        c.arg_name "host"
        c.desc "Host name for policy"
        c.flag [:h,:host]
    
        c.action do |global_options,options,args|
          host = options[:host]  
          policy_id = 'root'
          filename = 'integrations/ansible.yml'
          file = open(filename).read
          policy = file.gsub("<HOST>", host)
          
          method = Conjur::API::POLICY_METHOD_POST
          result = api.load_policy policy_id, policy, method: method
          puts "Loaded policy '#{policy_id}'"
          puts JSON.pretty_generate(result)
        end
      end
    end
  end