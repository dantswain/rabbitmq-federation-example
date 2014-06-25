# RabbitMQ Federation and Shovel Setup Example

This repository provides a way to explore RabbitMQ exchange federation and shovels for cross-datacenter messaging.
It was inspired by [https://github.com/jamescarr/rabbitmq-federation-example](https://github.com/jamescarr/rabbitmq-federation-example).
This repo uses Ruby to generate config files, with the goal of being able to generate an arbitrary number of nodes and
federation configuration.

## Usage

Edit `gen_configs.rb` to suit your needs and then run `ruby gen_configs.rb`.  This will create
one directory for each node defined as an instance of `Node`, a start script for each node,
and a `setup_feds` script to setup the federation links, and a `setup_shovels` script to setup
the shovel exchanges and queues.

* To create node configs and scripts: `ruby gen_configs.rb`
* To start nodes: `./start_all`
* To establish federation links: `./setup_feds`
* To set up shovels: `./setup_shovels`
* To stop nodes: `./stop_all`
* To remove all generated files: `./clean_all`

## Changing the topology (Templating usage)

The `Node` class can be used to generate a node:

``` ruby
Node.add(node_dir: "test_node",  # directory where configs are written
         name:      "test_node", # name used for connection => test_node@localhost
         port:      5000,        # main amqp port for connections
         mgmt_port: 3000)        # port where the management web app will run => http://localhost:3000/
```

The `Node.add` method will register the node with the `Node` class.  The
corresponding instance is then available via `Node[name]`.

The `FederationLink` class can be used to generate `rabbitmqctl` commands that establish
federation links and policies between the nodes:

``` ruby
# assume Node instances from and to
FederationLink.add(from,            # upstream node
                   to,              # downstream node
                   'federated_*',   # policy matching string => all exchanges with names
                                    #  matching 'federated_*' will have the federation
                                    #  policy applied
                   'max-hops' => 2) # set max-hops parameter
```

The `Shovel` class can be used to generate `rabbitmqctl` commands that establish shovel links
between exchanges or queues:

``` ruby
Shovel.add("shovel_name",   # name for the shovel
           on_node,         # node to which we want to install the shovel
           {                # configuration hash
             'src-uri' => source_node.uri,
             'src-exchange' => 'shovel_source',
             'dest-uri' => dest_node.uri,
             'dest-exchange' => 'shovel_dest'
           })
  .command(source_node.mgmt_port, 'declare exchange name="shovel_source"')
  .command(dest_node.mgmt_port, 'declare exchange name="shovel_dest')
```

Note Shovel has a `#command` method to stage `rabbitmqadmin` commands for
creating the necessary exchanges and queues.

## Example scripts

The federation example script shows how to set up a federated exchange (as per the example configs),
bind queues to the federated exchanges on a given node, post to one node and receive on another.

```
ruby federation_example.rb
```

Note that the example sometimes does not work correctly on the first run.  I'm not 100% sure why
this is - it seems to have something to do with setting up the exchange and queues in the same
script run.

The shovel example script shows how to publish to a source exchange and recieve the message on
all listening queues.

```
ruby shovel_example.rb
```
