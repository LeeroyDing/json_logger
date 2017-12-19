Elixir JSON Logger
==================

JSON Logger is a logger backend that outputs elixir logs in JSON format.

This project is originally designed to make Elixir apps work with Logstash easily. It aims at providing as much information for the log is possible, so the logs can be more easily analyzed by backend services like _Elasticsearch_.

Issues and PRs are welcome.

## Dependencies

This project requires [poison](https://hex.pm/packages/poison).

## Configuration

### Elixir Project

JSON Logger currently provides very few options:

* __level__: The minimal level of logging. There's no default of this option. Example: `level: :warn`

Example configuration: `config :logger, :json_logger, level: :info`

**TCP support is still experimental, please submit issues that you encounter.**

### Adding the logger backend

You need to add this backend to your `Logger`, preferably put this in your `Application`'s `start/2`.

```
Logger.add_backend Logger.Backends.JSON
```
