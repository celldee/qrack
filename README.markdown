# Qrack: A Ruby implementation of the AMQP wire protocol

## About

The aim of the Qrack project is to produce a Ruby implementation of the [AMQP](http://amqp.org) wire protocol that can be used as the basis for Ruby AMQP-compliant messaging products. If done properly it could become a sort of [Rack](http://rack.rubyforge.org) for the Ruby AMQP messaging community.

[amqp](http://github.com/tmm1/amqp) written by Aman Gupta already contains an implementation which will be used as the basis for this project. Some initial thoughts -

* The RabbitMQ AMQP JSON specification documents will be the source from which Ruby protocol classes will be generated due to licensing issues concerning the AMQP XML specification documents.

* Qrack should provide all of the Ruby classes necessary to implement the AMQP specification communication functionality whether mandatory or otherwise.

* Qrack should generate the classes from a particular version of the AMQP specification. Therefore, if you generate from the 0-9-1 spec you get a set of 0-9-1 protocol classes.

* A JSON specification will only need to be parsed once to produce the protocol classes and then the library will be ready for use.

* There should be no dependency on particular versions of the AMQP JSON specification.

* Qrack should be vendor neutral.

This project is at an early stage and we welcome suggestions and contributions to help make it a success.

## Acknowledgements

Thanks to [Alexis](http://github.com/monadic) for coming up with the name.