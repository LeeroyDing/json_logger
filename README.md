Elixir JSON Logger
==================

JSON Logger is a logger backend that outputs elixir logs in JSON format.

This project is originally designed to make Elixir apps work with Logstash easily. It aims at providing as much information for the log is possible, so the logs can be more easily analyzed by backend services like _Elasticsearch_.

Issues and PRs are welcome.

## Dependencies

This project requires [json](https://hex.pm/packages/json).

## Configuration

### Elixir Project

JSON Logger currently provides very few options:

* __level__: The minimal level of logging. There's no default of this option. Example: `level: :warn`
* __output__: The output of the log. Must be either `:console` or `{:udp, host, port}` or `{:tcp, host, port}. Example: `output: {:udp, "localhost", 514}`
* __metadata__: Whatever else you want in the log. Example: `metadata: "Some very important project"`

Example configuration: `config :logger, :json_logger, level: :info, output: {:udp, "localhost", 514}`

**TCP support is still experimental, please submit issues that you encounter.**


### In your application

You should add `json_logger` to your `mix.exs` as well. This step may not be necessary (if you know why please tell me).

```
defmodule MyMod.Mixfile do
  # ...
  def application do
    [applications: [:logger, :json_logger],
     mod: {MyMod, []}]
  end
  # ...
end
```

### Adding the logger backend

You need to add this backend to your `Logger`, preferably put this in your `Application`'s `start/2`.

```
Logger.add_backend Logger.Backends.JSONLogger
```

### If you wish to use Logstash with this library

Here is an example logstash configuration:

```
input {
  udp {
    port => 514
    type => "elixir_json_logging"
  }
}

filter {
  json {
    source => "message"
  }
}

output {
  stdout {
    codec => rubydebug
  }
}
```

Note that this configuration will probably break on your system (listening to a <1024 port). You **should** change the "port" to a larger value.
