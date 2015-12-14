require Logger

:application.start :logger
Logger.remove_backend :console
Logger.add_backend {Logger.Backends.JSON, :test}

ExUnit.start()
