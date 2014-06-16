# RabbitMQ Federation Setup Example

This repository provides a way to explore RabbitMQ exchange federation for cross-datacenter messaging.
It was inspired by [https://github.com/jamescarr/rabbitmq-federation-example](https://github.com/jamescarr/rabbitmq-federation-example).
This repo uses Ruby to generate config files, with the goal of being able to generate an arbitrary number of nodes and
federation configuration.

## Usage

Edit `gen_configs.rb` to suit your needs and then run `ruby gen_configs.rb`.  This will create
one directory for each node defined as an instance of `NodeTemplate`, a start script for each node,
and a `setup_feds` script to setup the federation links.
