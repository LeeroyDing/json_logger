defmodule Logger.Backends.JSON.Mixfile do
  use Mix.Project

  def project do
    [app: :json_logger,
     version: "0.1.0",
     elixir: ">= 1.0.0",
     deps: deps,
     description: "A Simple library for logging with JSON, best suited with Logstash.",
     package: package,
     source_url: "https://github.com/LeeroyDing/json_logger"]
  end

  def application, do: []

  defp deps do
    [{:json, "~> 0.3.2"}]
  end

  def package do
    [
      contributors: ["Leeroy Ding"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/LeeroyDing/json_logger"}
    ]
  end
end
