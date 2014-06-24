# RabbitMQ Federation Setup Example

This repository provides a way to explore RabbitMQ exchange federation for cross-datacenter messaging.
It was inspired by [https://github.com/jamescarr/rabbitmq-federation-example](https://github.com/jamescarr/rabbitmq-federation-example).
This repo uses Ruby to generate config files, with the goal of being able to generate an arbitrary number of nodes and
federation configuration.

## Usage

Edit `gen_configs.rb` to suit your needs and then run `ruby gen_configs.rb`.  This will create
one directory for each node defined as an instance of `NodeTemplate`, a start script for each node,
and a `setup_feds` script to setup the federation links.

* To create node configs and scripts: `ruby gen_configs.rb`
* To start nodes: `./start_all`
* To establish federation links: `./setup_feds`
* To stop nodes: `./stop_all`
* To remove all generated files: `./clean_all`

## Changing the topology (Templating usage)

The `NodeTemplate` class can be used to generate a node:

``` ruby
NodeTemplate.add(node_dir: "test_node",  # directory where configs are written
                 node_name: "test_node", # name used for connection => test_node@localhost
                 main_port: 5000,        # main amqp port for connections
                 mgmt_port: 3000)        # port where the management web app will run => http://localhost:3000/
```

The `NodeTemplate.add` method will register the node with the `NodeTemplate` class.  The
corresponding instance is then available via `NodeTemplate[node_name]`.

The `FederationLink` class can be used to generate `rabbitmqctl` commands that establish
federation links and policies between the nodes:

``` ruby
# assume NodeTemplate has instances with names 'from_node' and 'to_node'
FederationLink.add('from_node',   # downstream node name
                   'mybox',       # server hostname for upstream (assumes same)
                   'to_node',     # upstream node name
                   'federated_*', # policy matching string => all exchanges with names
                                  #  matching 'federated_*' will have the federation
                                  #  policy applied
                   uri: 'amqp://guest:guest@localhost:5000',
                                  # amqp connection string for upstream
                   'max-hops' => 2) # set max-hops parameter
```

## Example script

The example script shows how to set up a federated exchange (as per the example configs),
bind queues to the federated exchanges on a given node, post to one node and receive on another.

```
ruby federation_example.rb
```

Note that the example sometimes does not work correctly on the first run.  I'm not 100% sure why
this is - it seems to have something to do with setting up the exchange and queues in the same
script run.
