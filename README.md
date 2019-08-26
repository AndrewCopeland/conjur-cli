# conjur-cli

Command-line interface for Conjur.

*NOTE*: Conjur v4 users should use the `v5.x.x` release path. Conjur CLI `v6.0.0` only supports Conjur v5 and newer.

A complete reference guide is available at [conjur.org](https://www.conjur.org).

## Namespaces & more
```
root@6ca262d89186:/src/conjur-cli# conjur list
[

]
```

Currently nothing is in conjur, lets setup our syncronizer and start syncing secrets over from cyberark.
```
root@6ca262d89186:/src/conjur-cli# conjur list
...
  "cucumber:policy:vaultname/lob/AppTeam1Safe/delegation",
  "cucumber:group:vaultname/lob/AppTeam1Safe/delegation/consumers",
  "cucumber:policy:vaultname/lob/AppTeam1Safe/OracleDB",
  "cucumber:variable:vaultname/lob/AppTeam1Safe/OracleDB/username",
  "cucumber:variable:vaultname/lob/AppTeam1Safe/OracleDB/password",
  "cucumber:policy:vaultname/lob/AppTeam1Safe/UnixSSHKey",
  "cucumber:variable:vaultname/lob/AppTeam1Safe/UnixSSHKey/username",
  "cucumber:variable:vaultname/lob/AppTeam1Safe/UnixSSHKey/password",
  "cucumber:policy:vaultname/lob/AppTeam1MyApp/delegation",
  "cucumber:group:vaultname/lob/AppTeam1MyApp/delegation/consumers",
  "cucumber:policy:vaultname/lob/AppTeam1MyApp/MysqlMyApp",
  "cucumber:variable:vaultname/lob/AppTeam1MyApp/MysqlMyApp/username",
  "cucumber:variable:vaultname/lob/AppTeam1MyApp/MysqlMyApp/password"
...
```

So we have 2 safes syncing over 'AppTeam1Safe' & 'AppTeam1MyApp'.
'AppTeam1Safe' will represent a general safe that contains secrets used by the CI/CD pipeline.
'AppTeam1MyApp' will represent a safe for a specific application called 'MyApp'.

Now lets create our namesapce

```
root@6ca262d89186:/src/conjur-cli# conjur namespace create AppTeam1
Loading policy 'root'
{
  "created_roles": {
    "cucumber:host:AppTeam1/srv": {
      "id": "cucumber:host:AppTeam1/srv",
      "api_key": "362sr9339pq59g32r89rf2n4tfyn1xxfhyx29fknw0qkjtwneh8v70"
    }
  },
  "version": 1
}
```

A 'srv' host will be created in this namespace. (It is recommended to store the 'api_key' inside of the cyberark vault). 
This host will be used within AppTeam1's CI/CD pipeline to fetch secrets from conjur, create hosts, create applications and link safes & hosts to applications.

Currently our namespace does not contain any apps, hosts and does not have permission to any safe. So we really cannot do much.
We want to give a namespace access to a safe.
An admin user or user with appropriate permissions must be used to grant safes to a namespace.
To grant a namespace permissions to a safe perform the command below.

```
root@6ca262d89186:/src/conjur-cli# conjur namespace safe -n AppTeam1 -s AppTeam1Safe
...
root@6ca262d89186:/src/conjur-cli# conjur namespace safe -n AppTeam1 -s AppTeam1MyApp
...

```

Now our namespace has access to safe AppTeam1Safe & AppTeam1MyApp.

Lets login using our 'srv' account, open our namespace and create our first application.

```
root@6ca262d89186:/src/conjur-cli# conjur authn login
Enter your username to log into Conjur: host/AppTeam1/srv
Please enter your password (it will not be echoed):
Logged in
root@6ca262d89186:/src/conjur-cli# conjur namespace open AppTeam1
Opened namespace 'AppTeam1'
root@6ca262d89186:/src/conjur-cli# conjur app create MyApp
Loading policy 'AppTeam1'
{
  "created_roles": {
  },
  "version": 3
}
```

We created the application but it does not have any hosts or safes, lets create a host.

```
root@6ca262d89186:/src/conjur-cli# conjur host create authn MyApp.AppTeam1.comany.local
Loading policy 'AppTeam1'
{
  "created_roles": {
    "cucumber:host:AppTeam1/MyApp.AppTeam1.comany.local": {
      "id": "cucumber:host:AppTeam1/MyApp.AppTeam1.comany.local",
      "api_key": "3tpvcw9ageayf3p7zfv129xgjwq3dqvc353zw4k611tqa8w31kw3b26"
    }
  },
  "version": 4
}
```

Now link the host to our application.
```
root@6ca262d89186:/src/conjur-cli# conjur link host --host MyApp.AppTeam1.comany.local --app MyApp
Loading policy 'AppTeam1'
{
  "created_roles": {
  },
  "version": 5
}
```

Finally lets link our safe (AppTeam1MyApp) to our application.
```
root@6ca262d89186:/src/conjur-cli# conjur link safe --safe AppTeam1MyApp --app MyApp
Loading policy 'AppTeam1'
{
  "created_roles": {
  },
  "version": 6
}
```


Now lets login as our application host and verify our host only has access to the secrets it requires.

```
root@6ca262d89186:/src/conjur-cli# conjur authn login
Enter your username to log into Conjur: host/AppTeam1/MyApp.AppTeam1.comany.local
Please enter your password (it will not be echoed):
Logged in
root@6ca262d89186:/src/conjur-cli#
root@6ca262d89186:/src/conjur-cli#
root@6ca262d89186:/src/conjur-cli# conjur list
[
  "cucumber:variable:vaultname/lob/AppTeam1MyApp/MysqlMyApp/username",
  "cucumber:variable:vaultname/lob/AppTeam1MyApp/MysqlMyApp/password"
]
```


Awesome! Our host only has the secrets it requires and nothing more.


All of the commands above load policies and typically we want to store our policy in source control so it can be managed and updated easily.
Instead of loading the policies directly you can use the '--yaml' flag to display the policy instead of actually loading policy.
Examples below:

Policy loaded when creating an application.
```
root@6ca262d89186:/src/conjur-cli# conjur app create --yaml example
Policy Branch 'AppTeam1'
---
# create a owner group of the app being created
- !group app_example

- !grant
  role: !group app_example
  member: !group apps

# create the app policy
- !policy
  id: example
  owner: !group app_example
  annotations:
    clitype: csasaapp

  body:
  # this group will have read & execute permissions on all safes linked to this app
  - !group safes
  # this group repersents all of the hosts for this app
  - !group hosts

  # all hosts members of the hosts group will have access to the safes linked to this application
  - !grant
    role: !group safes
    member: !group hosts
```


Policy loaded when linking an app to a safe.
```
root@6ca262d89186:/src/conjur-cli# conjur link safe --yaml -a MyApp -s AppTeam1MyApp
Policy Branch 'AppTeam1'
---
- !grant
  role: !group safe_AppTeam1MyApp
  member: !group MyApp/safes
```


## Development

Create a sandbox environment in Docker using the `./dev` folder:

```sh-session
$ cd dev
dev $ ./start.sh
```

This will drop you into a bash shell in a container called `cli`.

The sandbox also includes a Postgres container and Conjur server container. The
environment is already setup to connect the CLI to the server:

* **CONJUR_APPLIANCE_URL** `http://conjur`
* **CONJUR_ACCOUNT** `cucumber`

To login to conjur, type the following and you'll be prompted for a password:

```sh-session
root@2b5f618dfdcb:/# conjur authn login admin
Please enter admin's password (it will not be echoed):
```

The required password is the API key at the end of the output from the
`start.sh` script.  It looks like this:

```
=============== LOGIN WITH THESE CREDENTIALS ===============

username: admin
api key : 9j113d35wag023rq7tnv201rsym1jg4pev1t1nb4419767ms1cnq00n

============================================================
```

At this point, you can use any CLI command you like.

### Running Cucumber

To install dev packages, run `bundle` from within the container:

```sh-session
root@2b5f618dfdcb:/# cd /usr/src/cli-ruby/
root@2b5f618dfdcb:/usr/src/cli-ruby# bundle
```

Then you can run the cucumber tests:

```sh-session
root@2b5f618dfdcb:/usr/src/cli-ruby# cucumber
...
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Copyright 2016-2017 CyberArk

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this software except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
