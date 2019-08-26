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

class Conjur::Command::Namespace < Conjur::Command
  require 'open-uri'
  desc "Manage namespaces"
  command :namespace do |namespaces|
    namespaces.desc "Create a namespace"
    namespaces.command :create do |c|
      c.desc "Name of the namespace"
      c.flag [:namespace, :n]

      c.desc "Output policy yaml rather than loading"
      c.switch [:y,:yaml]

      c.action do |_global, options, _args|
        namespace = options[:namespace] || _args[0]
        namespace = namespace.to_s.strip
        yaml = options[:yaml] || false

        if !namespace.empty?
          policy_id = "root"
          filename = 'templates/namespaces-create.yml'
          file = open(filename).read
          policy = file.gsub("{{ NAMESPACE }}", namespace)
          
          load_policy(policy_id, policy, yaml)
        else
          puts "ERROR: Namespace name was not provided"
        end
      end
    end

    namespaces.desc "Grant namespace access to a safe"
    namespaces.command :safe do |s|
      s.desc "Namespace"
      s.flag [:namespace, :n]

      s.desc "Safe name"
      s.flag [:safe, :s]

      s.desc "Output yaml policy rather than loading policy"
      s.flag [:yaml, :y]

      s.action do |_global, options, _args|
        if options.include?(:namespace) && options.include?(:safe)
          namespace = options[:namespace]
          safe_name = options[:safe]
          yaml = options[:yaml] || false

          if resource_exist? "policy", namespace
            consumers_group = get_safe_consumers_group safe_name
            
            policy_id = namespace
            filename = 'templates/namespaces-safe-namespace.yml'
            file = open(filename).read
            policy = file.gsub("{{ SAFE_NAME }}", safe_name)
            load_policy(policy_id, policy, yaml)
            
            policy_id = "root"
            filename = 'templates/namespaces-safe-root.yml'
            file = open(filename).read
            policy = file.gsub("{{ CONSUMERS_GROUP }}", consumers_group).gsub("{{ SAFE_NAME }}", safe_name).gsub("{{ NAMESPACE }}", namespace)
            load_policy(policy_id, policy, yaml)
          else
            puts "ERROR: namespace '#{namespace}' does not exists or you do not have permissions"
          end
        else
          puts "ERROR: namespace and safe were not provided"
        end
      end
    end

    namespaces.desc "Open a namespace"
    namespaces.command :open do |o|
      o.desc "Namespace"
      o.flag [:namespace, :n]

      o.action do |_global, options, _args|
        namespace = options[:namespace] || _args[0]
        namespace = namespace.to_s.strip

        if !namespace.empty?
          if resource_exist? "policy", namespace
            out_file = File.new(ENV["HOME"] + "/.conjur.namespace", "w")
            out_file.puts(namespace)
            out_file.close
            puts "Opened namespace '#{namespace}'"
          else
            puts "ERROR: namespace '#{namespace}' does not exists or you do not have permissions"
          end
        else
          puts "ERROR: namespace was not provided"
        end
      end
    end

    namespaces.desc "List namespaces"
    namespaces.command :list do |l|
      l.action do |global_options,options,args|
        resources = Conjur::Command.api.resources({kind: "policy", search: "csasanamespace"})
        resources.each do |resource|
          kind, id = get_kind_and_id_from_args([resource.id.to_s])
          puts "#{id}"
        end
      end
    end

    namespaces.desc "Present working namespace"
    namespaces.command :pwd do |l|
      l.action do |global_options,options,args|
        namespace = get_namespace()
        if namespace == nil
          puts "Currently not in a namespace"
        else
          puts "Conjur namespace '#{namespace}'"
        end
      end
    end

    namespaces.desc "Grant a namespace access to an authenticator service"
    namespaces.command :authn do |l|
      l.desc "Give namespace access to an iam authenticator service"
      l.command :iam do |i|
        i.desc "Namespace"
        i.flag [:namespace, :n]

        i.desc "Sevice ID"
        i.flag [:service, :s]

        i.desc "Output yaml policy rather than loading policy"
        i.flag [:yaml, :y]

        i.action do |global_options,options,args|
          namespace = options[:namespace]
          service_id = options[:service]
          yaml = options[:yaml] || false

          if namespace == nil
            exit_now! "Namespace '--namespace' was not provided"
          end

          if service_id == nil
            exit_now! "Service id '--service' was not provided"
          end

          if !resource_exist? "policy", namespace
            exit_now! "namespace '#{namespace}' does not exists or you do not have permissions"
          end
          
          policy_id = namespace
          filename = 'templates/namespaces-authn-iam-namespace.yml'
          file = open(filename).read
          policy = file.gsub("{{ SERVICE_ID }}", service_id)
          load_policy(policy_id, policy, yaml)
          
          policy_id = "root"
          filename = 'templates/namespaces-authn-iam-root.yml'
          file = open(filename).read
          policy = file.gsub("{{ SERVICE_ID }}", service_id).gsub("{{ NAMESPACE }}", namespace)
          load_policy(policy_id, policy, yaml)
        end

      end
      l.action do |global_options,options,args|
        namespace = get_namespace()
        if namespace == nil
          puts "Currently not in a namespace"
        else
          puts "Conjur namespace '#{namespace}'"
        end
      end
    end

  end

  def self.resource_exist?(kind, id)
    resouce = find_one_resource(kind, id)
    if resouce == nil
      false
    else
      true
    end
  end

  def self.find_one_resource(kind, id)
    resources = Conjur::Command.api.resources({kind: kind, search: id})
    full_id = "#{kind}:#{id}"
    found_resource = nil
    
    # This should never return more than one resource since we are looking for kind and ID
    resources.each do |resource|
      if resource.id.to_s.ends_with? full_id
        found_resource = resource
      end
    end
    found_resource
  end

  def self.get_safe_consumers_group(safe_name)
    policies=Conjur::Command.api.resources({kind: "policy", search: "/" + safe_name + "/delegation"})

    if policies.length < 1
      puts "ERROR: Safe #{safe_name} does not exists or you do not have permissions"
    elsif policies.length == 1
      # Get my policy ID 
      policy_id = policies[0].id.to_s.split(":", 3)[2]
      "#{policy_id}/consumers"
    else
      puts "ERROR: More than one safe was returned with name #{safe_name}"
    end
  end
end